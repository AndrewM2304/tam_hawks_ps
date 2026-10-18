from pathlib import Path
import hashlib,json,re,subprocess
from PIL import Image
root=Path.cwd();packet=root/'docs/testing/water-controls';local=root/'.local/water-controls'
sha=lambda b:hashlib.sha256(b).hexdigest()
def read(p):return json.loads(p.read_text())
core={str(p.relative_to(root)):sha(p.read_bytes()) for folder in ('game','tests','tools') for p in (root/folder).rglob('*') if p.is_file() and '__pycache__' not in p.parts}
core['project.godot']=sha((root/'project.godot').read_bytes())
checkpoint='db2b28e263a5305fe0d8064a967ed645a3c3d3fa'
for name,h in core.items():assert sha(subprocess.check_output(['git','show',checkpoint+':'+name]))==h,name
ordinary=read(local/'ordinary-02/receipt.json');native=read(local/'native-05/receipt.json');focused=read(local/'focused-03/receipt.json')
assert all(x['valid'] and x['source_stable'] and x['clean_log'] and x['exit_code']==0 for x in (ordinary,native,focused))
for name in ('ordinary-02','native-05'):
 before=read(local/name/'source-before.json');after=read(local/name/'source-after.json');assert before==after
 for path,h in core.items():assert before[path]==h,(name,path)
f_before=read(local/'focused-03/source-before.json')
f_different=[name for name,h in core.items() if f_before[name]!=h]
assert set(f_different)=={'game/art/assets/horizon/clyde_water.gdshader','tests/combo_integration_tests.gd'},f_different
assert focused['result_counts']==[['240','0']]
assert len(ordinary['result_counts'])==1 and ordinary['result_counts'][0][1]=='0'
comp=read(local/'native-05/comparison.json');assert comp['timing_pass'] and comp['native_samples']==480 and len(comp['results'])==4
assert all(v['timing_pass'] and v['draw_delta']==0 and v['primitive_delta']==0 for v in comp['results'])
assert len(native['image_sha256'])==26
for name,h in native['image_sha256'].items():
 p=packet/'native-05'/name;assert sha(p.read_bytes())==h
 with Image.open(p) as im:im.load();assert im.size==(1280,800)
original=(packet/'observers/original_water.gdshader').read_bytes();assert sha(original)==read(local/'baseline.json')['original_shader_sha256']
assert original in subprocess.check_output(['git','show','a6150d7:game/levels/outdoor_routes.gd'])
for name,candidate in [('native-01','water-candidate-01.gdshader'),('native-02','water-candidate-02.gdshader'),('native-03','water-candidate-03.gdshader'),('native-05','water-final.gdshader')]:
 assert sha((packet/'observers'/candidate).read_bytes())==read(local/name/'source-before.json')['game/art/assets/horizon/clyde_water.gdshader']
for phase,observer in [('native-01','capture-prior.gd'),('native-02','capture-prior.gd'),('native-03','capture-prior.gd'),('native-04','capture-04.gd'),('native-05','capture.gd')]:
 captured=read(local/phase/'source-before.json')
 assert sha((packet/'observers'/observer).read_bytes())==captured['.local/water-controls/capture.gd'],phase
 assert sha((packet/'observers/capture.sh').read_bytes())==captured['.local/water-controls/capture.sh'],phase
 assert sha((packet/'observers/views.gd').read_bytes())==captured['.local/horizon-background/views.gd'],phase
 assert sha((packet/'observers/original_water.gdshader').read_bytes())==captured['.local/water-controls/original_water.gdshader'],phase
for phase,driver in [('focused-01','focused.gd'),('focused-02','focused.gd'),('focused-03','focused.gd'),('combo-focused','combo-focused.gd')]:
 captured=read(local/phase/'source-before.json')
 assert sha((packet/'observers'/driver).read_bytes())==captured['.local/water-controls/'+driver],phase
 assert sha((packet/'observers/run_checked.py').read_bytes())==captured['.local/horizon-background/run_checked.py'],phase
assert sha((packet/'observers/run_checked.py').read_bytes())==read(local/'ordinary-02/source-before.json')['.local/horizon-background/run_checked.py']
body=(root/'docs/planning/BACKLOG.md').read_bytes().split(b'### M00-001',1)[1];body=b'### M00-001'+body
assert sha(body)=='48604a8ca25d8763f496a6c5ccbd8cf215d67583cc7d78dbc153c20694c14cae'
for phase in ('focused-01','manual-debug-01','focused-02','focused-03','native-01','native-02','native-03','native-04','native-05','combo-focused','ordinary-final','ordinary-02'):
 for p in (packet/phase).iterdir():
  original=local/phase/p.name
  assert p.read_bytes()==original.read_bytes(),str(p)
artifact_files={str(p.relative_to(packet)):sha(p.read_bytes()) for p in packet.rglob('*') if p.is_file() and p.name != 'audit.json'}
result={'valid':True,'runtime_checkpoint':checkpoint,'core_inputs':len(core),'ordinary_receipt':ordinary,'native_receipt':native,'native_comparison':comp,'focused_result':'240/0; two fingerprint differences: shader superseded by native05 and unrelated combo helper not executed in focused03. Final ordinary02 covers all44controller cases and the corrected combo driver.','focused_differences':f_different,'backlog_task_bodies_sha256':sha(body),'baseline_shader_sha256':sha((packet/'observers/original_water.gdshader').read_bytes()),'retained_artifact_sha256':artifact_files,'limits':'Linux software renderer only; fixed observers/diagnostic camera are not a human tour or continuous temporal/Mac/DualSense acceptance. All rejected images remain local; only selected examples are committed alongside complete raw timing/source/log receipts.'}
(packet/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'valid':True,'core_inputs':len(core),'ordinary_result':ordinary['result_counts'],'native_views':len(comp['results']),'native_samples':480,'native_images':26,'retained_artifacts':len(artifact_files)},indent=2))
