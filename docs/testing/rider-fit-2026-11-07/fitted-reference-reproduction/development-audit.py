from pathlib import Path
import importlib.util,json,hashlib,tempfile,shutil,struct
R=Path.cwd();B=R/'.local/fitted-rig-admission';spec=importlib.util.spec_from_file_location('ref',B/'build_reference.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);checks=[]
def ck(ok,label):checks.append({'pass':bool(ok),'check':label})
def digest(data):return hashlib.sha256(json.dumps(data,separators=(',',':'),allow_nan=False).encode()).hexdigest()
expected=json.loads((B/'epoch-08/project/tests/fitted-reference.json').read_text());expected_sha=hashlib.sha256((B/'epoch-08/project/tests/fitted-reference.json').read_bytes()).hexdigest();source=R/'.local/rider-fit-staging/release-reproduction-v13'
for assets in [R/'.local/rider-fit-staging/release-reproduction-v11-final',R/'.local/rider-fit-staging/epochs/v12-six/source/game/art/rider',source]:
 result=m.build(assets);ck(result==expected,'public-only reference exact semantic equality '+assets.name);ck(digest(result)==expected_sha,'public-only output byte SHA matches executed native reference '+assets.name)
ck(digest(m.build(source))==digest(m.build(source)),'deterministic repeated generation')
with tempfile.TemporaryDirectory(prefix='fitted-reference-') as temp:
 p=Path(temp)
 def reset():
  for name in ['fitted-manifest.json','fitted_outfit.glb','fitted_landmarks.json','fitted_head.obj']:shutil.copy2(source/name,p/name)
 def repin(name):
  d=json.loads((p/'fitted-manifest.json').read_text());d['outputs'][name]['sha256']=m.sha(p/name);(p/'fitted-manifest.json').write_text(json.dumps(d))
 def rejected(label,substring):
  try:m.build(p);ck(False,label)
  except ValueError as e:ck(substring in str(e),label)
 reset();(p/'fitted_outfit.glb').write_bytes((p/'fitted_outfit.glb').read_bytes()+b'bad');rejected('wrong actual asset pin rejected before interpretation','Source pin mismatch')
 reset();d=json.loads((p/'fitted_landmarks.json').read_text());d['UpperChest']['head_boundary_correspondence'].pop();(p/'fitted_landmarks.json').write_text(json.dumps(d));repin('fitted_landmarks.json');rejected('missing semantic Head record rejected even after honest metadata repin','Incomplete source46/47')
 reset();d=json.loads((p/'fitted_landmarks.json').read_text());d['UpperChest']['head_boundary_correspondence'][0]['source_body_vertex']=999999;(p/'fitted_landmarks.json').write_text(json.dumps(d));repin('fitted_landmarks.json');rejected('wrong source Head identity rejected independently of pin','Wrong source Head/chest')
 reset();d=json.loads((p/'fitted_landmarks.json').read_text());d['UpperChest']['head_boundary_correspondence'][0]['game_rest_position_m'][1]+=.01;(p/'fitted_landmarks.json').write_text(json.dumps(d));repin('fitted_landmarks.json');rejected('wrong source Head rest correspondence rejected independently of pin','Head correspondence departs')
 reset();d,blob=m.glb(p/'fitted_outfit.glb');d['nodes'][d['skins'][0]['joints'][0]]['name']='wrong_hips';data=json.dumps(d,separators=(',',':')).encode();data+=b' '*((-len(data))%4);raw=struct.pack('<III',0x46546c67,2,12+8+len(data)+8+len(blob))+struct.pack('<II',len(data),0x4e4f534a)+data+struct.pack('<II',len(blob),0x004e4942)+blob;(p/'fitted_outfit.glb').write_bytes(raw);repin('fitted_outfit.glb');rejected('changed native bone profile rejected after asset repin','original11bone')
result={'passes':sum(x['pass'] for x in checks),'failures':[x['check'] for x in checks if not x['pass']],'checks':checks,'generator_sha256':m.sha(B/'build_reference.py'),'reference_sha256':expected_sha,'scope':'Standalone standard-library public-source reference reproduction and malformed source controls; exact same reference bytes as native58/0. No new runtime/source asset or engine operation.'};(B/'reference-reproduction-audit.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2));raise SystemExit(bool(result['failures']))
