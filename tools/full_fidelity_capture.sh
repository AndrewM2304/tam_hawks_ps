#!/usr/bin/env bash
# Bounded real-action render evidence; no network, profile writes or hosted work.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
TASK_PRIVATE_DISPLAY=false
TASK_COHORT=all
TASK_PUSH_VIEW=contact
TASK_PUSH_SELECTION=all
TASK_NATIVE_SIZE=1280x800
while (($#)); do
  case "$1" in
    --private-display) TASK_PRIVATE_DISPLAY=true ;;
    --cohort) TASK_COHORT="${2:?--cohort needs all or push-contact}"; shift ;;
    --push-view) TASK_PUSH_VIEW="${2:?--push-view needs contact, front, side or chase}"; shift ;;
    --push-selection) TASK_PUSH_SELECTION="${2:?--push-selection needs all or natural-three}"; shift ;;
    --native-size) TASK_NATIVE_SIZE="${2:?--native-size needs1280x800 or640x400}"; shift ;;
    --help|-h) echo 'Usage: tools/full_fidelity_capture.sh [--private-display] [--cohort all|push-contact] [--push-view contact|front|side|chase] [--push-selection all|natural-three] [--native-size 1280x800|640x400]'; exit 0 ;;
    *) echo 'Usage: tools/full_fidelity_capture.sh [--private-display] [--cohort all|push-contact] [--push-view contact|front|side|chase] [--push-selection all|natural-three] [--native-size 1280x800|640x400]' >&2; exit 2 ;;
  esac
  shift
done
case "$TASK_COHORT" in all|push-contact) ;; *) echo "Invalid cohort: $TASK_COHORT" >&2; exit 2 ;; esac
case "$TASK_PUSH_VIEW" in contact|front|side|chase) ;; *) echo "Invalid push view: $TASK_PUSH_VIEW" >&2; exit 2 ;; esac
case "$TASK_PUSH_SELECTION" in all|natural-three) ;; *) echo "Invalid push selection: $TASK_PUSH_SELECTION" >&2; exit 2 ;; esac
if [[ "$TASK_PUSH_SELECTION" != all && "$TASK_COHORT" != push-contact ]]; then
  echo "Capture-only push selection requires the complete push-contact physical cohort." >&2
  exit 2
fi
case "$TASK_NATIVE_SIZE" in 1280x800|640x400) ;; *) echo "Invalid native size: $TASK_NATIVE_SIZE" >&2; exit 2 ;; esac
if [[ "$TASK_NATIVE_SIZE" != 1280x800 && "$TASK_COHORT" != push-contact ]]; then
  echo "Native640 is restricted to focused push motion diagnostics." >&2
  exit 2
fi
TASK_VERSION="$(./tools/run.sh --version)"
case "$TASK_VERSION" in 4.6.3.*) ;; *) echo "Expected Godot 4.6.3, found $TASK_VERSION" >&2; exit 1 ;; esac
mkdir -p .local
TASK_OUTPUT="$(mktemp -d "$TASK_ROOT/.local/full-fidelity-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")"
./tools/run.sh --headless --editor --import >"$TASK_OUTPUT/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:' "$TASK_OUTPUT/import.log"; then
  cat "$TASK_OUTPUT/import.log" >&2
  exit 1
fi
./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 \
  --script tools/full_fidelity_capture_smoke.gd >"$TASK_OUTPUT/snapshot-smoke.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:' "$TASK_OUTPUT/snapshot-smoke.log"; then
  cat "$TASK_OUTPUT/snapshot-smoke.log" >&2
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
  # The installed container has four CPU cores; avoid llvmpipe oversubscription.
  export LP_NUM_THREADS=4
fi

python3 - "$TASK_ROOT" "$TASK_OUTPUT" "$TASK_COHORT" "$TASK_PUSH_VIEW" "$TASK_PUSH_SELECTION" "$TASK_NATIVE_SIZE" <<'PY'
import hashlib, json, math, os, pathlib, re, shutil, signal, struct, subprocess, sys, time, zlib
root, output = map(pathlib.Path, sys.argv[1:3])
cohort, push_view, push_selection, native_size = sys.argv[3:7]
width,height=map(int,native_size.split("x"))
if (width,height) not in ((1280,800),(640,400)) or ((width,height)!=(1280,800) and cohort!="push-contact"):
    raise SystemExit("Invalid focused native capture dimensions.")
destination = root / 'docs/testing/screenshots' / ('full-fidelity' if cohort=='all' else ('push-natural-three' if push_selection=='natural-three' else 'push-contact-'+push_view)+('' if native_size=='1280x800' else '-native640'))
sys.path.insert(0,str(root/'tools'))
from full_fidelity_capture_png import PixelSpoolEncoder, decode_proven_rgba8

def fingerprint():
    inputs = [root/'project.godot', root/'tools/run.sh', root/'tools/xorg-dummy.conf']
    inputs += sorted((root/'tools').glob('full_fidelity_capture*'))
    for directory in ('game', 'tests'):
        inputs += sorted(p for p in (root/directory).rglob('*') if p.is_file())
    return {str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(set(inputs))}

def png_details(path, pixels=None):
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
    if not ended or dimensions is None or dimensions[:2]!=(width,height): raise ValueError('PNG dimensions/end: '+str(path))
    png_width,png_height,depth,colour,_,_,interlace=dimensions
    channels={2:3,6:4}.get(colour)
    if depth!=8 or channels is None or interlace or len(zlib.decompress(compressed))!=png_height*(1+png_width*channels):
        raise ValueError('PNG complete rows: '+str(path))
    details={'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'resolution':[png_width,png_height],'png_crc_and_rows_valid':True}
    if pixels is not None:
        decoded=decode_proven_rgba8(data,width,height)
        digest=hashlib.sha256(decoded).hexdigest()
        if digest!=pixels['rgba8_sha256'] or len(decoded)!=pixels['bytes']: raise ValueError('PNG changed native pixels: '+str(path))
        details.update(decoded_rgba8_sha256=digest,native_pixels_equal=True)
    return details

for executable in ('ffmpeg','ffprobe'):
    if shutil.which(executable) is None: raise SystemExit('Installed '+executable+' is required; nothing was downloaded.')
before=fingerprint()
command=[str(root/'tools/run.sh'),'--rendering-method','gl_compatibility','--audio-driver','Dummy',
    '--windowed','--resolution',native_size,'--disable-render-loop','--fixed-fps','60',
    '--script','tools/full_fidelity_capture.gd','--',str(output),cohort,push_view,push_selection,native_size]
process=None
encoder=PixelSpoolEncoder(output,width,height)
encoder.start()
capture_started=time.monotonic()
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
        environment=dict(os.environ,FULL_FIDELITY_RAW_SPOOL='1')
        process=subprocess.Popen(command,cwd=root,env=environment,stdout=log,stderr=subprocess.STDOUT,start_new_session=True)
        deadline=time.monotonic()+10800
        while process.poll() is None:
            if encoder.error is not None:
                stop(); raise SystemExit('Lossless pixel worker failed: '+str(encoder.error))
            if time.monotonic()>deadline:
                stop(); raise SystemExit('Motion capture exceeded its declared 10800-second local bound.')
            try: process.wait(timeout=1)
            except subprocess.TimeoutExpired: pass
        code=process.returncode
finally:
    stop()
    encoder.finish()
log=(output/'engine.log').read_text()
print(log,end='',flush=True)
if code or re.search(r'SCRIPT ERROR:|Parse Error:|ERROR:|FAIL:',log):
    raise SystemExit('Motion capture failed; no current evidence published: '+str(output))
report=json.loads((output/'manifest.json').read_text())
if report.get('native_capture_size')!=[width,height]:raise SystemExit('Native size does not match source-bound capture declaration.')
after=fingerprint()
changed=sorted(p for p in before.keys()|after.keys() if before.get(p)!=after.get(p))
if changed or report.get('failures')!=0 or not report.get('production_main') or report.get('profile_writes_enabled'):
    raise SystemExit('Invalid/source-changed motion capture; no publication: '+str(changed))
clips=report.get('clips',[])
required={'nollie_native_launch','rotation_native_spin_left','rotation_native_spin_right','named_gap_native_central','setup_boneless','setup_no_comply','setup_moving_no_comply','bail_getup','interrupted_tumble_recovery',
    'unsupported_plant_boneless','unsupported_plant_no_comply','accepted_revert_manual_link',
    'high_wall_bail','results_recovery_fade','bail_floor_seam',
    'bail_native_bank_20','bail_native_bank_35','bail_native_bank_45',
    'manual_nose_to_pogo','manual_nose_to_casper_manual',
    'manual_after_shove_to_pogo','manual_after_shove_to_casper_manual',
    'bowl_world_approach','bowl_native_lap','halfpipe_connected_return','spine_native_transfer',
    'curved_visual_bowl_lap','curved_visual_halfpipe_faces','curved_visual_native_bank','curved_visual_native_bank_45',
    'curved_visual_bowl_flip_return','grind_grade_forward','grind_grade_backwards','grind_grade_rail_pivot',
    'platform_roof_carry','platform_roof_ollie','platform_roof_boneless','platform_endpoint_stop',
    'cart_parked_turn',
    'service_gate_route','cone_cruise_native','skitch_native_cart','wallride_wallie_combo',
    'park_lap_park_full_loop','park_lap_park_bank_cut',
    'sunken_park_active_lap_climb','sunken_park_active_lap_entry','sunken_park_active_lap_visit',
    'sunken_park_native_entry_hint','sunken_park_beginner_circuit','sunken_park_safe_exit',
    'sunken_park_deep_bowl_native_lip','sunken_park_shallow_bowl_native_lip',
    'sunken_park_deep_native_carve','sunken_park_street_native_grind','sunken_park_hip_native_transfer',
    'sunken_park_native_port_departure','sunken_park_geometry_beginner','sunken_park_geometry_compact_hip',
    'exchange_south_line','civic_lower_island','station_low_manual','barras_forecourt_line','clyde_south_link',
    'clyde_south_middle','clyde_south_east_west','clyde_south_link_capture'}
names={c['id'] for c in clips}
if report.get('cohort')!=cohort or report.get('complete_repertoire_coverage')!=(cohort=='all') or report.get('push_capture_selection','all')!=push_selection:
    raise SystemExit('Capture coverage declaration does not match requested cohort.')
actual_catalog=set(report.get('catalog_ids',[]))
observed_catalog=set()
previous_native={}
for sample in report.get('native_timeline',[]):
    phase=sample['phase']; tick=sample['state']['physics_frame']
    if phase in previous_native and tick-previous_native[phase]!=1:
        raise SystemExit('Missing native physics observations in '+phase+': '+str(tick-previous_native[phase]))
    previous_native[phase]=tick
    state=sample['state']
    if state.get('last_trick_id') in actual_catalog: observed_catalog.add(state['last_trick_id'])
    for identity in state.get('accepted_score_identities',[]):
        if identity in actual_catalog: observed_catalog.add(identity)
        elif identity.startswith('gap:'): observed_catalog.add('named_gap')
if cohort=='all':
    if len(actual_catalog)!=78 or actual_catalog-observed_catalog:
        raise SystemExit('Missing real accepted catalog identities: '+str(sorted(actual_catalog-observed_catalog)))
    report['accepted_catalog_identity_coverage']={'total':len(actual_catalog),'observed':sorted(observed_catalog),'complete':True}
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
else:
    physical_required={'push_contact_'+name for name in ('regular','fakie','from_rest','brake','brake_return','pop_catch','pop_early')}
    required={'push_contact_'+name for name in ('regular','fakie','from_rest')} if push_selection=='natural-three' else physical_required
    if len(names)!=len(clips) or names!=required or set(report.get('observed_phase_ids',[]))!=physical_required:
        raise SystemExit('Incomplete declared physical/visual push coverage: '+str(sorted(required-names)))
    if push_selection=='natural-three':
        expected_views={'push_contact_regular':'front','push_contact_from_rest':'side','push_contact_fakie':'chase'}
        if report.get('per_case_push_view')!=expected_views or report.get('visual_phase_coverage_complete') or set(report.get('unrecorded_phase_ids',[]))!=physical_required-required:
            raise SystemExit('Capture-only phase policy is missing or overclaims discarded phases.')
        if {s['phase']for s in report['native_timeline']}!=physical_required:
            raise SystemExit('Capture selection discarded a physical native trace.')
        for clip in clips:
            frames=clip.get('frames',[])
            if len(frames)!=117 or clip['native_steps']!=117 or clip['sample_stride']!=1:
                raise SystemExit('Natural push requires every72press+45release native frame: '+clip['id'])
            if any(b['state']['physics_frame']-a['state']['physics_frame']!=1 for a,b in zip(frames,frames[1:])):
                raise SystemExit('A claimed normal-speed push clip skipped a physics tick: '+clip['id'])
    report['accepted_catalog_identity_coverage']={'total':len(actual_catalog),'observed':sorted(observed_catalog),'complete':False,'scope':'Focused push cohort only; full78 acceptance remains separate.'}
frame_rate=int(report['motion_sample_hz'])
if frame_rate!=(60 if cohort=='push-contact' else 15): raise SystemExit('Unexpected native sample rate')
total_frames=0
public_files=[]
proofs=report.get('synchronization_proofs',[])
if len(proofs)!=3 or [p['id'] for p in proofs]!=['overview_before_contact','first_contact_inspection','return_to_production_chase']:
    raise SystemExit('Missing actual camera/Canvas synchronization boundary proofs.')
for proof in proofs:
    proof.update(png_details(output/proof['file'],proof['pixels']))
    pixels=decode_proven_rgba8((output/proof['file']).read_bytes(),width,height)
    x,y=proof['canvas_pixel']; offset=(y*width+x)*4
    if list(pixels[offset:offset+4])!=proof['canvas_expected'] or not proof['same_native_frame']:
        raise SystemExit('Stale current-Canvas/native-frame boundary: '+proof['id'])
    if proof['id']!='overview_before_contact' and len(proof['markers'])!=2:
        raise SystemExit('Missing actual head/board projected pixel evidence.')
    for marker in proof['markers']:
        px,py=marker['projected_pixel']; matches=[]
        for y in range(max(0,int(py)-12),min(height,int(py)+13)):
            for x in range(max(0,int(px)-12),min(width,int(px)+13)):
                r,g,b,_=pixels[(y*width+x)*4:(y*width+x+1)*4]
                if (r>191 and r-g>51 and r-b>51) if marker['color_channel']=='red' else (g>191 and g-r>51 and g-b>51):
                    matches.append((x+.5,y+.5))
        if len(matches)<4: raise SystemExit('Current projected 3D marker absent: '+proof['id'])
        error=math.hypot(sum(x for x,y in matches)/len(matches)-px,sum(y for x,y in matches)/len(matches)-py)
        if error>2.5: raise SystemExit('Current actual head/board projection disagrees with decoded PNG: '+proof['id'])
        marker.update(independent_png_pixel_count=len(matches),independent_png_centroid_error=error)
    proof['independent_png_projection_and_canvas_valid']=True
    public_files.append(proof['file'])
if cohort=='all' and (len(report.get('overviews',[]))!=7 or {o['file'] for o in report['overviews']}!={'overview_'+name+'.png' for name in ['exchange','george','central','barras','clyde','park','sunken_kelvingrove']}):
    raise SystemExit('Expected all six district overviews and the new sunken facility overview.')
for overview in report['overviews']:
    overview.update(png_details(output/overview['file'],overview['pixels']))
    public_files.append(overview['file'])
for clip in clips:
    name=clip['id']
    if not re.fullmatch('[a-z0-9_]+',name): raise SystemExit('Unsafe clip identifier')
    frames=clip.get('frames',[])
    if len(frames)<4: raise SystemExit('Insufficient motion samples: '+name)
    for frame in frames: frame.update(png_details(output/frame['file'],frame['pixels']))
    total_frames+=len(frames)
    movie=output/(name+'.mp4')
    subprocess.run(['ffmpeg','-v','error','-nostdin','-y','-framerate',str(frame_rate),'-i',
        str(output/'frames'/name/'%05d.png'),'-c:v','libx264','-preset','medium','-crf','22',
        '-pix_fmt','yuv420p','-movflags','+faststart',str(movie)],check=True,timeout=120)
    probe=json.loads(subprocess.run(['ffprobe','-v','error','-select_streams','v:0','-show_entries',
        'stream=codec_name,width,height,nb_frames,r_frame_rate,duration','-of','json',str(movie)],
        check=True,capture_output=True,text=True,timeout=15).stdout)['streams'][0]
    if int(probe['nb_frames'])!=len(frames) or (probe['width'],probe['height'])!=(width,height) or probe['r_frame_rate']!=str(frame_rate)+'/1':
        raise SystemExit('Video stream validation failed: '+name)
    subprocess.run(['ffmpeg','-v','error','-nostdin','-i',str(movie),'-f','null','-'],check=True,timeout=120)
    clip['video']={'file':movie.name,'sha256':hashlib.sha256(movie.read_bytes()).hexdigest(),
        'bytes':movie.stat().st_size,'stream':probe,'decoded_all_frames':True}
    public_files.append(movie.name)
    selected={0,len(frames)//2,len(frames)-1}
    if name.startswith('push_contact_'):
        plant=[(abs(float(f['state'].get('push_phase',0))-.30),i) for i,f in enumerate(frames)
            if f['state'].get('push_blend',0)>.98 and f['state'].get('push_phase',1)<.60]
        recovery=[(abs(float(f['state'].get('push_phase',0))-.80),i) for i,f in enumerate(frames)
            if f['state'].get('push_blend',0)>.90 and f['state'].get('push_phase',0)>.60]
        if plant: selected.add(min(plant)[1])
        if recovery: selected.add(min(recovery)[1])
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
if encoder.frames!=total_frames+len(report['overviews'])+len(proofs) or list(output.rglob('*.rgba')) or list(output.rglob('*.rgba.tmp')):
    raise SystemExit('Encoded native frame inventory does not match the complete manifest.')
concat=output/'phase-reel.ffconcat'
concat.write_text('ffconcat version 1.0\n'+''.join("file '"+str(output/c['video']['file']).replace("'","'\\''")+"'\n" for c in clips))
metadata=[';FFMETADATA1','title=Tam Hawks Pro Skater - native phase review']
cursor=0
for clip in clips:
    end=cursor+len(clip['frames'])
    metadata+=['[CHAPTER]','TIMEBASE=1/'+str(frame_rate),'START='+str(cursor),'END='+str(end),'title='+clip['id']]
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
    capture_bound_seconds=10800,capture_elapsed_seconds=time.monotonic()-capture_started,
    lossless_png_worker={'encoded_frames':encoder.frames,'max_native_buffers_pending':encoder.max_backlog,
        'total_worker_seconds':encoder.total_seconds,'all_decoded_native_pixel_hashes_equal':True},
    git_commit=subprocess.run(['git','rev-parse','HEAD'],cwd=root,check=True,capture_output=True,text=True).stdout.strip(),
    git_dirty=bool(subprocess.run(['git','status','--porcelain'],cwd=root,check=True,capture_output=True,text=True).stdout.strip()),
    engine_log_sha256=hashlib.sha256((output/'engine.log').read_bytes()).hexdigest(),
    import_log_sha256=hashlib.sha256((output/'import.log').read_bytes()).hexdigest(),
    snapshot_smoke_log_sha256=hashlib.sha256((output/'snapshot-smoke.log').read_bytes()).hexdigest())
if fingerprint()!=before: raise SystemExit('Source changed during encoding; no publication.')
(output/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
destination.mkdir(parents=True,exist_ok=True)
for filename in public_files+['manifest.json','engine.log','import.log','snapshot-smoke.log']:
    (destination/filename).parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(output/filename,destination/filename)
print('FULL_FIDELITY_CAPTURE_OK: %s cohort, %d source-stable clips, %d real frames, %d checks, zero failures in %s'%
    (cohort,len(clips),total_frames,report['checks'],destination))
print('MANIFEST_SHA256: '+hashlib.sha256((output/'manifest.json').read_bytes()).hexdigest())
PY
