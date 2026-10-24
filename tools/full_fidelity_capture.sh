#!/usr/bin/env bash
# Bounded real-action render evidence; no network, profile writes or hosted work.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE_DISPLAY=false
while (($#)); do
  case "$1" in
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --help|-h) echo 'Usage: tools/full_fidelity_capture.sh [--private-display]'; exit 0 ;;
    *) echo 'Usage: tools/full_fidelity_capture.sh [--private-display]' >&2; exit 2 ;;
  esac
  shift
done
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/full-fidelity-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
./tools/run.sh --headless --editor --import >"$TASK_OUTPUT/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_OUTPUT/import.log"; then
  cat "$TASK_OUTPUT/import.log" >&2
  exit 1
fi
TASK_DISPLAY_PID=""
cleanup() {
  if [[ -n "$TASK_DISPLAY_PID" ]]; then
    kill -TERM "$TASK_DISPLAY_PID" 2>/dev/null || true
    for attempt in {1..20}; do
      kill -0 "$TASK_DISPLAY_PID" 2>/dev/null || break
      sleep 0.1
    done
    kill -KILL "$TASK_DISPLAY_PID" 2>/dev/null || true
    wait "$TASK_DISPLAY_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
if [[ "$(uname -s)" == Linux && ( -z "${DISPLAY:-}" || "$TASK_PRIVATE_DISPLAY" == true ) ]]; then
  [[ -x /usr/lib/xorg/Xorg ]] || { echo 'A graphical desktop or installed Xorg dummy driver is required.' >&2; exit 1; }
  /usr/lib/xorg/Xorg -displayfd 3 -config "$TASK_ROOT/tools/xorg-dummy.conf" \
    -logfile "$TASK_OUTPUT/xorg.log" -noreset -nolisten tcp \
    3>"$TASK_OUTPUT/display" >"$TASK_OUTPUT/xorg-console.log" 2>&1 &
  TASK_DISPLAY_PID=$!
  for attempt in {1..50}; do
    [[ -s "$TASK_OUTPUT/display" ]] && break
    if ! kill -0 "$TASK_DISPLAY_PID" 2>/dev/null; then cat "$TASK_OUTPUT/xorg-console.log" >&2; exit 1; fi
    sleep 0.1
  done
  [[ -s "$TASK_OUTPUT/display" ]] || { echo 'Private display startup timed out.' >&2; exit 1; }
  export DISPLAY=":$(cat "$TASK_OUTPUT/display")"
  export LIBGL_ALWAYS_SOFTWARE=1
fi

python3 - "$TASK_ROOT" "$TASK_OUTPUT" <<'PY'
import hashlib, json, os, pathlib, re, shutil, signal, struct, subprocess, sys, zlib
root, output = map(pathlib.Path, sys.argv[1:])
destination = root / 'docs/testing/screenshots/full-fidelity'

def fingerprint():
    inputs = [root/'project.godot', root/'tools/run.sh', root/'tools/xorg-dummy.conf']
    inputs += sorted((root/'tools').glob('full_fidelity_capture*'))
    for directory in ('game', 'tests'):
        inputs += sorted(p for p in (root/directory).rglob('*') if p.is_file())
    return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(inputs))}

def png_details(path):
    data=path.read_bytes()
    if data[:8]!=b'\x89PNG\r\n\x1a\n': raise ValueError('Invalid PNG: '+str(path))
    offset, compressed, dimensions, ended=8,bytearray(),None,False
    while offset<len(data):
        size=struct.unpack('>I',data[offset:offset+4])[0]
        kind=data[offset+4:offset+8]; chunk=data[offset+8:offset+8+size]
        checksum=struct.unpack('>I',data[offset+8+size:offset+12+size])[0]
        if zlib.crc32(kind+chunk)&0xffffffff!=checksum: raise ValueError('PNG CRC: '+str(path))
        if kind==b'IHDR': dimensions=struct.unpack('>IIBBBBB',chunk)
        if kind==b'IDAT': compressed.extend(chunk)
        if kind==b'IEND': ended=True
        offset+=size+12
    if not ended or dimensions is None or dimensions[:2]!=(1280,800): raise ValueError('PNG dimensions/end: '+str(path))
    width,height,depth,colour,_,_,interlace=dimensions
    channels={2:3,6:4}.get(colour)
    if depth!=8 or channels is None or interlace or len(zlib.decompress(compressed))!=height*(1+width*channels):
        raise ValueError('PNG complete rows: '+str(path))
    return {'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'resolution':[width,height],'png_crc_and_rows_valid':True}

for executable in ('ffmpeg','ffprobe'):
    if shutil.which(executable) is None: raise SystemExit('Installed '+executable+' is required; nothing was downloaded.')
before=fingerprint()
command=[str(root/'tools/run.sh'),'--rendering-method','gl_compatibility','--audio-driver','Dummy',
    '--windowed','--resolution','1280x800','--disable-render-loop','--fixed-fps','60',
    '--script','tools/full_fidelity_capture.gd','--',str(output)]
process=None
def stop(*_):
    if process is not None and process.poll() is None:
        os.killpg(process.pid,signal.SIGTERM)
        try: process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid,signal.SIGKILL); process.wait(timeout=5)
signal.signal(signal.SIGTERM,lambda *_:(stop(),sys.exit(143)))
signal.signal(signal.SIGINT,lambda *_:(stop(),sys.exit(130)))
print('Capturing full-fidelity motion in '+str(output),flush=True)
try:
    with (output/'engine.log').open('w') as log:
        process=subprocess.Popen(command,cwd=root,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
        try: code=process.wait(timeout=1800)
        except subprocess.TimeoutExpired:
            stop(); raise SystemExit('Motion capture exceeded its 1800-second bound.')
finally: stop()
log=(output/'engine.log').read_text()
print(log,end='',flush=True)
if code or re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:',log):
    raise SystemExit('Motion capture failed; no current evidence published: '+str(output))
report=json.loads((output/'manifest.json').read_text())
after=fingerprint()
changed=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
if changed or report.get('failures')!=0 or not report.get('production_main') or report.get('profile_writes_enabled'):
    raise SystemExit('Invalid/source-changed motion capture; no publication: '+str(changed))
clips=report.get('clips',[])
required={'setup_boneless','setup_no_comply','setup_moving_no_comply','bail_getup','interrupted_tumble_recovery',
    'unsupported_plant_boneless','unsupported_plant_no_comply','accepted_revert_manual_link',
    'high_wall_bail','results_recovery_fade','bail_floor_seam',
    'bail_native_bank_20','bail_native_bank_35','bail_native_bank_45',
    'manual_nose_to_pogo','manual_nose_to_casper_manual',
    'manual_after_shove_to_pogo','manual_after_shove_to_casper_manual',
    'bowl_world_approach','bowl_native_lap','halfpipe_connected_return','spine_native_transfer',
    'curved_visual_bowl_lap','curved_visual_halfpipe_faces','curved_visual_native_bank','curved_visual_native_bank_45',
    'curved_visual_bowl_flip_return',
    'platform_roof_carry','platform_roof_ollie','platform_roof_boneless','platform_endpoint_stop',
    'cart_parked_turn',
    'service_gate_route','cone_cruise_native','skitch_native_cart','wallride_wallie_combo',
    'park_lap_park_full_loop','park_lap_park_bank_cut',
    'exchange_south_line','civic_lower_island','station_low_manual','barras_forecourt_line','clyde_south_link',
    'clyde_south_middle','clyde_south_east_west','clyde_south_link_capture'}
names={c['id'] for c in clips}
families=report.get('catalog_families',{})
for family,count,prefix in [('flip',24,'flip_'),('grab',8,'grab_native_'),('lip',9,'lip_'),('special',6,'special_')]:
    ids=families.get(family,[])
    if len(ids)!=count or len(set(ids))!=count: raise SystemExit('Incomplete catalog family '+family)
    required.update(prefix+name for name in ids)
for family,count in [('grind',10),('manual',11)]:
    ids=families.get(family,[])
    if len(ids)!=count or len(set(ids))!=count: raise SystemExit('Incomplete catalog family '+family)
    for name in ids:
        required.add(('grind_grind_pivot' if name=='grind_pivot' else 'grind_native_'+name) if family=='grind'
            else ('manual_native_'+name if name in ('manual','nose_manual') else 'manual_'+name))
if len(names)!=len(clips) or required-names or len(clips)<50:
    raise SystemExit('Incomplete actual motion coverage: '+str(sorted(required-names)))
total_frames=0
public_files=[]
if len(report.get('overviews',[]))!=6: raise SystemExit('Expected all six current-source district overviews.')
for overview in report['overviews']:
    overview.update(png_details(output/overview['file']))
    public_files.append(overview['file'])
for clip in clips:
    name=clip['id']
    if not re.fullmatch('[a-z0-9_]+',name): raise SystemExit('Unsafe clip identifier')
    frames=clip.get('frames',[])
    if len(frames)<4: raise SystemExit('Insufficient motion samples: '+name)
    for frame in frames: frame.update(png_details(output/frame['file']))
    total_frames+=len(frames)
    movie=output/(name+'.mp4')
    subprocess.run(['ffmpeg','-v','error','-nostdin','-y','-framerate','15','-i',
        str(output/'frames'/name/'%05d.png'),'-c:v','libx264','-preset','medium','-crf','22',
        '-pix_fmt','yuv420p','-movflags','+faststart',str(movie)],check=True,timeout=120)
    probe=json.loads(subprocess.run(['ffprobe','-v','error','-select_streams','v:0','-show_entries',
        'stream=codec_name,width,height,nb_frames,r_frame_rate,duration','-of','json',str(movie)],
        check=True,capture_output=True,text=True,timeout=15).stdout)['streams'][0]
    if int(probe['nb_frames'])!=len(frames) or (probe['width'],probe['height'])!=(1280,800) or probe['r_frame_rate']!='15/1':
        raise SystemExit('Video stream validation failed: '+name)
    subprocess.run(['ffmpeg','-v','error','-nostdin','-i',str(movie),'-f','null','-'],check=True,timeout=120)
    clip['video']={'file':movie.name,'sha256':hashlib.sha256(movie.read_bytes()).hexdigest(),
        'bytes':movie.stat().st_size,'stream':probe,'decoded_all_frames':True}
    public_files.append(movie.name)
    selected={0,len(frames)//2,len(frames)-1}
    contact=[(abs(float(f['state'].get('setup_phase',0))-.65),i) for i,f in enumerate(frames) if f['state'].get('setup_active')]
    if contact: selected.add(min(contact)[1])
    bearing=[]
    for index,frame in enumerate(frames):
        state=frame['state']
        if (name.startswith('grind_') and state.get('grinding')) or (name.startswith('manual_') and state.get('manual_active')) \
            or (name.startswith('lip_') and name=='lip_'+state.get('lip_id','') and state.get('lip_active')) \
            or (name.startswith('grab_') and state.get('grab_remaining',0)>0 and state.get('grab_blend',0)>.9) \
            or (name=='skitch_native_cart' and state.get('skitch_caught')):
            bearing.append(index)
    if bearing: selected.add(bearing[len(bearing)//2])
    posters=[]
    for index in sorted(selected):
        poster=name+'-%05d.png'%index
        shutil.copyfile(output/frames[index]['file'],output/poster)
        posters.append({'file':poster,'source_frame':index,**png_details(output/poster)})
        public_files.append(poster)
    clip['review_frames']=posters
    print('MOTION_CLIP_OK: '+name+' '+str(len(frames))+' frames',flush=True)
concat=output/'phase-reel.ffconcat'
concat.write_text('ffconcat version 1.0\n'+''.join("file '"+str(output/c['video']['file']).replace("'","'\\''")+"'\n" for c in clips))
metadata=[';FFMETADATA1','title=Tam Hawks Pro Skater - native phase review']
cursor=0
for clip in clips:
    end=cursor+len(clip['frames'])
    metadata+=['[CHAPTER]','TIMEBASE=1/15','START='+str(cursor),'END='+str(end),'title='+clip['id']]
    cursor=end
(output/'phase-reel.ffmetadata').write_text('\n'.join(metadata)+'\n')
reel=output/'all-phases.mp4'
subprocess.run(['ffmpeg','-v','error','-nostdin','-y','-safe','0','-f','concat','-i',str(concat),
    '-i',str(output/'phase-reel.ffmetadata'),'-map_metadata','1','-map_chapters','1','-c','copy',
    '-movflags','+faststart',str(reel)],check=True,timeout=120)
reelprobe=json.loads(subprocess.run(['ffprobe','-v','error','-select_streams','v:0','-show_entries',
    'stream=codec_name,width,height,nb_frames,r_frame_rate,duration','-show_chapters','-of','json',str(reel)],
    check=True,capture_output=True,text=True,timeout=15).stdout)
if int(reelprobe['streams'][0]['nb_frames'])!=total_frames or len(reelprobe['chapters'])!=len(clips):
    raise SystemExit('Complete phase reel frame/chapter validation failed.')
subprocess.run(['ffmpeg','-v','error','-nostdin','-i',str(reel),'-f','null','-'],check=True,timeout=180)
report['phase_reel']={'file':reel.name,'sha256':hashlib.sha256(reel.read_bytes()).hexdigest(),
    'bytes':reel.stat().st_size,'decoded_all_frames':True,'frames':total_frames,'chapters':len(clips)}
public_files.append(reel.name)
report.update(source_sha256=before,source_changed_during_run=False,source_stable_capture_set=True,
    command=command,total_video_frames=total_frames,
    git_commit=subprocess.run(['git','rev-parse','HEAD'],cwd=root,check=True,capture_output=True,text=True).stdout.strip(),
    git_dirty=bool(subprocess.run(['git','status','--porcelain'],cwd=root,check=True,capture_output=True,text=True).stdout.strip()),
    engine_log_sha256=hashlib.sha256((output/'engine.log').read_bytes()).hexdigest(),
    import_log_sha256=hashlib.sha256((output/'import.log').read_bytes()).hexdigest())
if fingerprint()!=before: raise SystemExit('Source changed during encoding; no publication.')
(output/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
destination.mkdir(parents=True,exist_ok=True)
for filename in public_files+['manifest.json','engine.log','import.log']:
    shutil.copyfile(output/filename,destination/filename)
print('FULL_FIDELITY_CAPTURE_OK: %d source-stable clips, %d real frames, %d checks, zero failures in %s'%
    (len(clips),total_frames,report['checks'],destination))
print('MANIFEST_SHA256: '+hashlib.sha256((output/'manifest.json').read_bytes()).hexdigest())
PY
