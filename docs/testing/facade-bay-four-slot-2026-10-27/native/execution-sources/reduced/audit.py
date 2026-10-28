"""Independent offline audit of a reduced four-slot Glasgow bay.
No Blender/Godot dependency. Original references must be exact preserved Git bytes.
This does not establish imported texture memory, appearance, live admission or FPS.
"""
from collections import Counter
from pathlib import Path
import argparse
import gzip
import hashlib
import json
import math
import struct
import subprocess
import sys

SLOTS = ['01_Original_sandstone','02_Painted_forest_joinery','03_Opaque_glazing','04_Aged_dark_metal']
LOD_COUNTS = {'near':9864,'mid':3544,'far':648}
PART_COUNTS = {'near':246,'mid':142,'far':54}
BOUNDS = ([-3.25,0,-0.5],[3.25,16,0.36])
RECTS = {1:(16,432,224,496),2:(16,16,496,400),3:(272,432,496,496)}
ENTRY = {'Recessed door','Door opaque glass','Stone threshold','Door handle','Handle mount','Door metal handle silhouette'}
COMPONENTS = {5120:('b',1),5121:('B',1),5122:('h',2),5123:('H',2),5125:('I',4),5126:('f',4)}
LENGTHS = {'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}


def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(obj):return json.dumps(obj,sort_keys=True,separators=(',',':')).encode()
def norm(v):return math.sqrt(sum(x*x for x in v))
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def cross(a,b):return (a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])

def glb(path):
 raw=path.read_bytes();magic,version,size=struct.unpack_from('<III',raw)
 assert (magic,version,size)==(0x46546c67,2,len(raw)),('header',path)
 cursor=12;chunks={}
 while cursor<len(raw):
  size,kind=struct.unpack_from('<II',raw,cursor);cursor+=8
  assert size%4==0 and cursor+size<=len(raw)
  assert kind not in chunks;chunks[kind]=raw[cursor:cursor+size];cursor+=size
 assert cursor==len(raw) and set(chunks)=={0x4e4f534a,0x004e4942}
 return json.loads(chunks[0x4e4f534a]),chunks[0x004e4942],raw

def read(doc,binary,index):
 acc=doc['accessors'][index];assert 'sparse' not in acc and not acc.get('normalized',False)
 view=doc['bufferViews'][acc['bufferView']];assert view['buffer']==0
 code,width=COMPONENTS[acc['componentType']];n=LENGTHS[acc['type']]
 stride=view.get('byteStride',n*width);offset=view.get('byteOffset',0)+acc.get('byteOffset',0)
 assert stride>=n*width and offset+(acc['count']-1)*stride+n*width<=view.get('byteOffset',0)+view['byteLength']<=len(binary)
 return [struct.unpack_from('<'+code*n,binary,offset+i*stride) for i in range(acc['count'])]

def arrays(doc,binary,p):
 values={k:read(doc,binary,v) for k,v in p['attributes'].items()}
 values['INDICES']=[x[0] for x in read(doc,binary,p['indices'])]
 return values

def triangle_key(material,corners):return int(material),tuple(sorted(tuple(round(float(v),5) for v in corner) for corner in corners))
def records(doc,binary,uv='TEXCOORD_0',recover_atlas_class=False):
 result=Counter()
 for p in doc['meshes'][0]['primitives']:
  a=arrays(doc,binary,p);pos=a['POSITION'];source=a[uv];ids=a['INDICES']
  for start in range(0,len(ids),3):
   tri=ids[start:start+3];material=p['material']
   if recover_atlas_class and material!=0:
    chosen=[]
    for index in tri:
     u,v=a['TEXCOORD_0'][index];v=1-v
     matches=[m for m,(x0,y0,x1,y1) in RECTS.items() if (x0+.25)/512-1e-6<=u<=(x1-.25)/512+1e-6 and (y0+.25)/512-1e-6<=v<=(y1-.25)/512+1e-6]
     assert len(matches)==1,('atlas class',u,v,matches);chosen.append(matches[0])
    assert len(set(chosen))==1;material=chosen[0]
   result[triangle_key(material,[(*pos[i],*source[i]) for i in tri])]+=1
 return result


def inspect(path,lod,reference):
 doc,binary,raw=glb(path)
 assert doc['asset']['version']=='2.0'
 assert len(doc['meshes'])==len(doc['nodes'])==len(doc['buffers'])==1
 assert not any(doc.get(k) for k in ['images','textures','samplers','extensionsUsed','extensionsRequired'])
 assert 'uri' not in doc['buffers'][0]
 assert doc['materials']==[{'name':name,'alphaMode':'OPAQUE','doubleSided':False} for name in SLOTS]
 node=doc['nodes'][0]
 assert node.get('translation',[0,0,0])==[0,0,0] and node.get('rotation',[0,0,0,1])==[0,0,0,1] and node.get('scale',[1,1,1])==[1,1,1] and 'matrix' not in node
 surfaces=doc['meshes'][0]['primitives'];assert len(surfaces)==4 and [p['material'] for p in surfaces]==list(range(4))
 low=[math.inf]*3;high=[-math.inf]*3;tris=vertices=0;surfreport=[];maxn=maxt=maxdot=0
 decoded=[]
 for p in surfaces:
  assert p.get('mode',4)==4 and set(p['attributes'])=={'POSITION','NORMAL','TANGENT','TEXCOORD_0'}
  assert all(doc['accessors'][v]['componentType']==5126 for v in p['attributes'].values())
  a=arrays(doc,binary,p);decoded.append(a)
  pos,normal,tangent,uv,ids=[a[k] for k in ['POSITION','NORMAL','TANGENT','TEXCOORD_0','INDICES']]
  assert len(pos)==len(normal)==len(tangent)==len(uv)
  assert len(ids)%3==0 and min(ids)>=0 and max(ids)<len(pos)
  assert all(math.isfinite(x) for k,v in a.items() if k!='INDICES' for row in v for x in row)
  for n,t in zip(normal,tangent):
   maxn=max(maxn,abs(norm(n)-1));maxt=max(maxt,abs(norm(t[:3])-1));maxdot=max(maxdot,abs(sum(x*y for x,y in zip(n,t))))
   assert abs(abs(t[3])-1)<.001
  for point in pos:
   for axis in range(3):low[axis]=min(low[axis],point[axis]);high[axis]=max(high[axis],point[axis])
  for start in range(0,len(ids),3):
   i,j,k=ids[start:start+3]
   assert norm(cross(sub(pos[j],pos[i]),sub(pos[k],pos[i])))>1e-10
   d1,d2=sub(uv[j],uv[i]),sub(uv[k],uv[i]);assert abs(d1[0]*d2[1]-d1[1]*d2[0])>1e-12
  tris+=len(ids)//3;vertices+=len(pos)
  surfreport.append({'slot':p['material'],'name':SLOTS[p['material']],'triangles':len(ids)//3,'vertices':len(pos),'decoded_attributes_sha256':sha(canonical(a))})
 assert maxn<.005 and maxt<.005 and maxdot<.005
 assert tris==LOD_COUNTS[lod]
 assert all(abs(a-b)<1e-4 for a,b in zip(low+high,BOUNDS[0]+BOUNDS[1]))
 olddoc,oldbin,oldraw=glb(reference/'two_surface/generated'/path.name)
 expected=records(olddoc,oldbin,'TEXCOORD_1',True);actual=records(doc,binary)
 assert expected==actual,('every reduced triangle/class/authoredUV must match preserved two-surface geometry',lod,sum((expected-actual).values()),sum((actual-expected).values()))
 parity={'source':'preserved two_surface geometry and original SourceUV1; class independently recovered from atlas regions','matched_material_position_authored_uv_triangles':sum(actual.values()),'micrometre_rounding_decimals':5}
 if lod!='near':
  fd,fb,_=glb(reference/'fitted/generated'/path.name)
  olddecoded=[arrays(fd,fb,p) for p in fd['meshes'][0]['primitives']]
  assert decoded==olddecoded,('mid/far complete decoded attributes+index order must be exact fitted',lod)
  parity['all_position_normal_tangent_uv_index_arrays_exact_fitted']=True
 return {'file':path.name,'sha256':sha(raw),'bytes':len(raw),'triangles':tris,'vertices':vertices,'surfaces':surfreport,'bounds_min_m':low,'bounds_max_m':high,'maximum_normal_length_error':maxn,'maximum_tangent_length_error':maxt,'maximum_normal_tangent_dot':maxdot,'parity':parity},actual


def parts_audit(generation,payload,reference,actuals):
 old=json.loads((reference/'two_surface/generation.json').read_text())['parts']
 result=[]
 for lod in LOD_COUNTS:
  metadata=generation['parts'][lod];parts=payload['parts'][lod]
  assert len(metadata)==len(parts)==len(old[lod])==PART_COUNTS[lod]
  union=Counter();checks=[]
  for index,(now,oracle,part) in enumerate(zip(metadata,old[lod],parts)):
   assert now['index']==part['part_index']==index and now['source_class']==part['source_class']==oracle['source_class']
   for key in ['part','dimensions_m','bounds_min_m','bounds_max_m','bevel_radius_m','bevel_segments_override','entry_lift_m','triangles']:
    assert now[key]==oracle[key],(lod,index,key,now[key],oracle[key])
   triangles=part['position_uv_triangles'];assert len(triangles)==oracle['triangles']
   assert all(len(tri)==3 and all(len(corner)==5 and all(math.isfinite(v) for v in corner) for corner in tri) for tri in triangles)
   points=[corner[:3] for tri in triangles for corner in tri]
   low=[min(p[axis] for p in points) for axis in range(3)];high=[max(p[axis] for p in points) for axis in range(3)]
   assert max(abs(a-b) for a,b in zip(low+high,oracle['bounds_min_m']+oracle['bounds_max_m']))<1e-5,(lod,index,'actual per-part bounds')
   perpart=Counter(triangle_key(part['source_class'],tri) for tri in triangles);assert sum(perpart.values())==oracle['triangles'];union.update(perpart)
   if oracle['part']=='Stone threshold':assert abs(high[1]-.53)<1e-5 and abs(low[1]-.33)<1e-5
   checks.append({'part_index':index,'part':oracle['part'],'source_class':oracle['source_class'],'triangles':len(triangles),'actual_bounds_min_m':low,'actual_bounds_max_m':high,'position_authored_uv_triangles_sha256':sha(canonical(sorted(perpart.items()))),'matches_historical_part_envelope_and_count':True})
  assert union==actuals[lod],('every prejoin part triangle must occur in actual exported GLB; exact multiplicity',lod,sum((union-actuals[lod]).values()),sum((actuals[lod]-union).values()))
  result.append({'lod':lod,'parts':len(parts),'all_parts_triangle_union_equals_actual_glb':True,'part_checks':checks})
 return result


def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--candidate',type=Path,required=True);parser.add_argument('--repeat',type=Path);parser.add_argument('--reference',type=Path,default=Path(__file__).parent/'reference/art_source/glasgow_bay');parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
 candidate=args.candidate;reference=args.reference
 report={'schema':1,'status':'REJECTED; incomplete audit','method':'Independent stdlib GLB decoder plus immutable historical reduced geometry/material-phase oracle and all-part union. No engine or render launched.','tested':[],'not_tested':['Godot import and original3495320-byte imported texture budget','rendered appearance or chamfer highlight quality','live integration, draw/frame timing, target-Mac/human acceptance']}
 try:
  original_inputs={str(p.relative_to(reference)):sha(p.read_bytes()) for p in sorted(reference.rglob('*')) if p.is_file()}
  report['reference_sha256']=original_inputs;report['auditor_sha256']=sha(Path(__file__).read_bytes())
  generation=json.loads((candidate/'generation.json').read_text());assert set(generation['preserved_inputs_sha256'])==set(original_inputs);payload=json.loads(gzip.decompress((candidate/'part-triangles.json.gz').read_bytes()))
  report['candidate_manifest_sha256']=sha((candidate/'generation.json').read_bytes());report['part_triangle_payload_sha256']=sha((candidate/'part-triangles.json.gz').read_bytes())
  maps={name:sha((reference/'textures'/name).read_bytes()) for name in ['sandstone_basecolor.png','sandstone_normal_opengl.png','sandstone_orm.png','opaque_glazing_basecolor.png']}
  assert generation['original_shared_maps']==maps
  report['original_shared_maps_sha256']=maps
  if args.repeat:
   for name in ['generation.json','part-triangles.json.gz']:
    assert (candidate/name).read_bytes()==(args.repeat/name).read_bytes(),('factory-startup metadata/payload differ',name)
   report['repeat_metadata_and_part_payload_byte_identical']=True
  assets=[];actuals={}
  for lod in LOD_COUNTS:
   name='glasgow_bay_'+lod+'.glb';asset,actuals[lod]=inspect(candidate/name,lod,reference)
   if args.repeat:
    assert (candidate/name).read_bytes()==(args.repeat/name).read_bytes(),('two factory-startup exports differ',lod)
    asset['repeat_sha256']=sha((args.repeat/name).read_bytes())
   assets.append(asset)
  report['assets']=assets;report['parts']=parts_audit(generation,payload,reference,actuals)
  for name,digest in generation['preserved_inputs_sha256'].items():
   assert name in original_inputs and digest==original_inputs[name],('reference input hash',name)
  assert original_inputs=={str(p.relative_to(reference)):sha(p.read_bytes()) for p in sorted(reference.rglob('*')) if p.is_file()}
  report.update(status='PASS: offline geometry/slot/UV/attribute/reproducibility only',passed=True)
  report['tested']=['strict GLB container/accessor bounds','four exact original named opaque single-sided material slots and no embedded textures/material payloads','exact9864/3544/648 triangle budgets and invariant bounds','finite unit orthogonal normal/tangent and nondegenerate geometric/UV triangles','every material+position+original UV triangle equals immutable reduced two-surface reference','all mid/far decoded position/normal/tangent/UV/index arrays identical fitted','all246/142/54 actual prejoin part envelopes/counts and exact multiplicity union equals exported GLBs','actual stone entry threshold0.53m and original entry lift','factory-startup repeat GLB byte equality' if args.repeat else 'repeat exports NOT PROVIDED','immutable extracted reference hashes unchanged']
 except BaseException as exc:
  report.update(passed=False,failure=repr(exc));raise
 finally:
  args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps(report,indent=2)+'\n')
 print(json.dumps({'status':report['status'],'assets':[{k:asset[k] for k in ['file','triangles','sha256']} for asset in report['assets']],'part_counts':[p['parts'] for p in report['parts']],'output':str(args.output)}))

if __name__=='__main__':main()
