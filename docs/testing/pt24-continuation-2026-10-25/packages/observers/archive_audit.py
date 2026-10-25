from pathlib import Path, PurePosixPath
import hashlib,json,plistlib,stat,struct,subprocess,sys,zipfile,shutil
root=Path.cwd();build=Path(sys.argv[1]).resolve();out=root/'docs/testing/pt24-continuation-2026-10-25/packages';out.mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
meta=json.loads((build/'BUILD-METADATA.json').read_text());tested=json.loads((root/'docs/testing/pt24-continuation-2026-10-25/validation/final/source-before.json').read_text());receipt=json.loads((root/'docs/testing/pt24-continuation-2026-10-25/validation/final/receipt.json').read_text());assert receipt['valid']
paths=[root/'project.godot',root/'docs/testing/horizon-background/observers/run_checked.py']
paths += [p for folder in ('game','tests','tools') for p in (root/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
actual={str(p.relative_to(root)):sha(p) for p in sorted(set(paths))};assert actual==tested,'Required-tested input membership or hashes changed'
assert meta['working_tree_dirty'] is False,'Export was not made from a clean commit'
for name,expected in meta['source_files_sha256'].items():
 assert sha(root/name)==expected,name
 data=subprocess.check_output(['git','show',meta['git_commit']+':'+name]);assert hashlib.sha256(data).hexdigest()==expected,name
common=set(tested)&set(meta['source_files_sha256']);assert all(tested[n]==meta['source_files_sha256'][n] for n in common)
records=[]
for platform in ['linux','macos']:
 archive=build/f'TamHawksProSkater-{platform}.zip'; report=json.loads((build/f'{platform}-resources.json').read_text());package_report=json.loads((build/platform/'PACKAGED-RESOURCES.json').read_text())
 assert report['main_scene_loaded'] and len(report['voice_streams'])==3 and len(report['textures'])==4 and len(report['human_meshes'])==4
 with zipfile.ZipFile(archive) as z:
  assert z.testzip() is None
  for name in z.namelist():assert not PurePosixPath(name).is_absolute() and '..' not in PurePosixPath(name).parts,name
  assert json.loads(z.read('BUILD-METADATA.json'))==meta
  assert hashlib.sha256(z.read(package_report['pack_path'])).hexdigest()==package_report['pack_sha256']
  notices=[n for n in z.namelist() if n.startswith('NOTICES/')]
  assert len(notices)>=13
  if platform=='macos':
   app='Tam Hawks Pro Skater.app/Contents/';info=plistlib.loads(z.read(app+'Info.plist'));exe=app+'MacOS/'+info['CFBundleExecutable'];header=z.read(exe)[:64];magic,count=struct.unpack('>II',header[:8]);assert magic==0xcafebabe and count==2
   arches={struct.unpack('>I',header[8+20*i:12+20*i])[0] for i in range(count)};assert arches=={0x01000007,0x0100000c};arch_names=['arm64','x86_64']
  else:
   exe='TamHawksProSkater.x86_64';assert z.read(exe)[:4]==b'\x7fELF';arch_names=['x86_64']
  assert (z.getinfo(exe).external_attr>>16)&stat.S_IXUSR
 records.append({'platform':platform,'file':archive.name,'bytes':archive.stat().st_size,'sha256':sha(archive),'pack_sha256':package_report['pack_sha256'],'architectures':arch_names,'crc_valid':True,'notice_records':len(notices),'main_scene_and_imported_resources_verified':True})
for filename in ['BUILD-METADATA.json','SHA256SUMS.txt','linux-resources.json','macos-resources.json','linux-export.log','macos-export.log','linux-resources.log','macos-resources.log']:
 shutil.copy2(build/filename,out/filename)
result={'valid':True,'build_directory':str(build.relative_to(root)),'git_commit':meta['git_commit'],'working_tree_clean_at_export':True,'required_suite_receipt_sha256':sha(root/'docs/testing/pt24-continuation-2026-10-25/validation/final/receipt.json'),'required_input_count':len(tested),'all_required_inputs_still_identical':True,'package_input_count':len(meta['source_files_sha256']),'package_test_overlap':len(common),'all_package_inputs_match_checkout_and_git_objects':True,'runtime_source_sha256':meta['runtime_source_sha256'],'archives':records,'cross_platform_pack_bytes_identical':records[0]['pack_sha256']==records[1]['pack_sha256'],'macos_signed':False,'macos_notarized':False,'macos_executable_launched':False,'target_performance_accepted':False,'limits':['Linux-loaded Mac resource pack is not execution of the Mac binary.','Source and archive validation do not establish target performance, controller, audio, visual or human acceptance.']}
(out/'ARCHIVE-AUDIT.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
