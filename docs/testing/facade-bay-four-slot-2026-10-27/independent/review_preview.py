from pathlib import Path
from collections import defaultdict
import argparse,hashlib,json,re
from PIL import Image,ImageDraw,ImageFont
import numpy as np
parser=argparse.ArgumentParser(description='Independently verify a retained four-way source/native preview and create inspection sheets; no engines.');parser.add_argument('run',type=Path);parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
p=args.run.resolve();out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
m=json.loads((p/'input-manifest.json').read_text());r=json.loads((p/'receipt.json').read_text());d=json.loads((p/'report.json').read_text())
assert r['unchanged_sources']==len(m['sources_sha256'])==77
assert r['source_before_sha256']==r['source_after_sha256']==m['sources_sha256']
live_sources=0
for name,expected in m['sources_sha256'].items():
 live=Path(m['source_paths'][name])
 if live.exists():
  assert sha(live)==expected;live_sources+=1
 assert sha(p/'execution-sources'/name)==expected
for name,expected in m['staged_executed_recipes_sha256'].items():assert sha(p/name)==expected
for item in m['assets']+m['textures']:assert sha(p/item['path'])==item['sha256']
for item in d['meshes']+d['textures']:
 path=p/item['path'].removeprefix('res://');assert sha(Path(str(path)+'.import'))==item['import_sha256']
 assert sha(path)==item.get('source_sha256',item.get('sha256'))
assert sha(p/'report.json')==r['report_sha256']
for name in ['import-initial.log','import-configured.log','engine.log']:
 text=(p/name).read_text();assert not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:|FAIL:|TIMEOUT',text),name
assert d['errors']==[] and len(d['images'])==32 and len(d['native_lod_samples'])==44 and len(d['meshes'])==12 and len(d['textures'])==7
assert d['variant_imported_texture_data_bytes']=={'fitted':3495320,'reduced':3495320,'atlas_compressed':3503512,'atlas_lossless':6998751}
assert d['environment']['shadow_max_distance']==r['fixture_shadow_range_m']==75
assert not any(d[k] for k in ['performance_measurement','live_integration']) and not any(r[k] for k in ['performance_measurement','mac_result','runtime_files_written'])
views=defaultdict(dict);images={}
for item in r['images']:
 path=p/item['file'];assert sha(path)==item['sha256'];img=Image.open(path).convert('RGB');assert img.size==(1920,1080);arr=np.array(img);assert hashlib.sha256(arr.tobytes()).hexdigest()==item['decoded_rgb_sha256'];images[item['file']]=img
for item in d['images']:
 assert item['visible_primitives_including_fixture']-item['fixture_only_primitives']==item['actual_holder_primitive_delta']==item['expected_triangles']
 assert item['fixture_only_primitives']==14
 assert item['visible_objects']==item['visible_draw_calls']==(6 if item['variant'].startswith('atlas_') else 8)
 views[item['view']][item['variant']]=item
matched=[]
for view,variants in sorted(views.items()):
 assert set(variants)=={'fitted','reduced','atlas_compressed','atlas_lossless'}
 for key in ['camera_position','target','fov','fixture_only_primitives','expected_native_lod','native_seed_distance_m']:
  assert all(v[key]==variants['fitted'][key] for v in variants.values()),(view,key)
 base=variants['fitted'];new=variants['reduced'];a=np.array(images[base['image']]);b=np.array(images[new['image']]);delta=np.abs(a.astype(np.int16)-b.astype(np.int16))
 if base['expected_native_lod']!='near':assert np.array_equal(a,b),('unchangedmid/far should match nativepixels',view)
 matched.append({'view':view,'native_lod':base['expected_native_lod'],'fitted_triangles':base['actual_holder_primitive_delta'],'reduced_triangles':new['actual_holder_primitive_delta'],'same_four_slot_objects_draws':True,'fitted_reduced_exact_pixels':bool(np.array_equal(a,b)),'diagnostic_mean_rgb_byte_delta':float(delta.mean()),'diagnostic_changed_pixel_fraction':float(np.any(delta,axis=2).mean())})
for item in d['native_lod_samples']:assert item['actual_visible_primitives']==item['expected_triangles']
for item in r['decoded_imported_mips']:
 path=p/item['image'];assert sha(path)==item['sha256'];img=Image.open(path).convert('RGB');assert list(img.size)==item['size'];assert hashlib.sha256(np.array(img).tobytes()).hexdigest()==item['decoded_rgb_sha256']
assert len(r['decoded_imported_mips'])==34
variants=['fitted','reduced','atlas_compressed','atlas_lossless'];font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',16)
for group,start in enumerate([0,4]):
 sheet=Image.new('RGB',(1920,1200),'white');draw=ImageDraw.Draw(sheet)
 for row,view in enumerate(sorted(views)[start:start+4]):
  for col,variant in enumerate(variants):
   frame=images[variant+'-'+view+'.png'];frame.thumbnail((480,270));sheet.paste(frame,(col*480,row*300+26));draw.text((col*480+4,row*300+3),variant+' / '+view,fill='black',font=font)
 sheet.save(out/('scene-sheet-'+str(group+1)+'.png'))
# The originals remain untouched; sheets are inspection aids only.
report={'scope':'Independent raw native receipt/source/counter/pixel audit. Visual assessment is recorded separately after inspecting original frames.','passed':True,'receipt_sha256':sha(p/'receipt.json'),'report_sha256':sha(p/'report.json'),'source_snapshots_verified':77,'still_available_original_source_paths_verified':live_sources,'reviewer_script_sha256':sha(Path(__file__)),'scene_png_hashes_and_decodes_verified':32,'actual_decoded_mip_png_hashes_and_decodes_verified':34,'native_lod_samples_verified':44,'mesh_source_and_import_hashes_verified':12,'texture_source_and_import_hashes_verified':7,'actual_imported_map_data_bytes':d['variant_imported_texture_data_bytes'],'matched_camera_and_counter_controls':matched,'fitted_reduced_four_slot_draws_objects_perframe':8,'atlas_two_slot_draws_objects_perframe':6,'fixture_primitives_perframe':14,'not_tested':['GPUresidentmemory','livegameintegration/routes/collisions/camera','frametiming/performance/targetMac','fullcityart/owneracceptance']}
(out/'AUDIT.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
