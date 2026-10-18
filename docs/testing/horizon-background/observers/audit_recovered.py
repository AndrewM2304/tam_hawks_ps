"""Bind recovered checkpoint validation to actual source; no performance admission."""
from pathlib import Path
import hashlib,json,subprocess
from PIL import Image
root=Path.cwd();packet=root/'docs/testing/horizon-background';evidence=packet/'evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text())
def core(m):return {k:v for k,v in m.items() if k=='project.godot' or k.startswith(('game/','tests/','tools/'))}
paths=[root/'project.godot']+[p for d in ('game','tests','tools') for p in (root/d).rglob('*') if p.is_file() and '__pycache__' not in p.parts]
current={str(p.relative_to(root)):sha(p) for p in sorted(paths)}
assert len(current)==367
checkpoint='15981c11e71632a8e2bd4ffadefb7dfc87825ca6'
for name,digest in current.items():assert hashlib.sha256(subprocess.check_output(['git','show',checkpoint+':'+name])).hexdigest()==digest,name
receipts={}
for name in ('recovered-focused-01','ordinary-recovered-01','recovered-preview-01'):
 f=evidence/name;r=read(f/'receipt.json');before=read(f/'source-before.json');after=read(f/'source-after.json')
 assert r['valid'] and r['source_stable'] and r['clean_log'] and before==after and core(before)==current,name
 receipts[name]={'receipt_sha256':sha(f/'receipt.json'),'source_inputs':len(before),'core_inputs':len(core(before)),'started_london':r['started_london'],'completed_london':r['completed_london'],'wall_seconds':r['wall_seconds']}
assert read(evidence/'recovered-focused-01/receipt.json')['result_counts']==[['34','0']]
assert read(evidence/'ordinary-recovered-01/receipt.json')['result_counts'][-1]==['2139','0']
f=evidence/'recovered-preview-01';r=read(f/'receipt.json');capture=read(f/'capture.json');comparison=read(f/'comparison.json')
assert capture['valid'] and capture['functional_counts']==[34,0] and len(capture['views'])==10
images={}
for name,digest in r['image_sha256'].items():
 p=f/name;assert sha(p)==digest
 with Image.open(p) as im:im.load();assert im.size==(1280,800)
 images[name]=digest
assert len(images)==12 and comparison['matched_views']==3 and comparison['native_samples']==400
for v in capture['views']:
 assert v['grounded'] and v['stable']>=3 and v['xz_error']<=.15 and abs(v['actual_player'][1]-v['ground_reference'])<=.1 and v['contact_y'] is not None and v['far']==220
body=(root/'docs/planning/BACKLOG.md').read_bytes();body=body[body.index(b'### M00-001'):];body_sha=hashlib.sha256(body).hexdigest()
assert body_sha=='48604a8ca25d8763f496a6c5ccbd8cf215d67583cc7d78dbc153c20694c14cae'
manifest=read(root/'game/art/assets/horizon/manifest.json');assert manifest['external_inputs']==[] and sha(root/manifest['source'])==manifest['generator_sha256']
for name,record in manifest['files'].items():assert sha(root/'game/art/assets/horizon'/name)==record['sha256']
reproduction=read(packet/'reproduction-512.json');assert all(v['identical'] for v in reproduction.values())
report={'valid_source_regression_audit':True,'runtime_checkpoint':checkpoint,'core_inputs':len(current),'receipts':receipts,'decoded_pngs':len(images),'image_sha256':images,'focused_counts':[34,0],'required_counts':[2139,0],'preview_native_samples':400,'preview_matched_views':3,'preview_timing_pass':comparison['timing_pass'],'preview_pass_count':sum(v['timing_pass'] for v in comparison['results']),'full_37_view_performance_admitted':False,'gpu_layer_readback_verified':False,'backlog_full_body_sha256':body_sha,'asset_manifest_sha256':sha(root/'game/art/assets/horizon/manifest.json'),'limits':'Source/regression audit plus limited native preview. All-area strict rendering admission remains pending; failed/partial historical runs retain their verdicts. No target Mac/controller/fun/flicker/final-art acceptance.'}
(packet/'audit-recovered.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ('image_sha256','receipts')},indent=2))
