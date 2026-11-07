from pathlib import Path
import json,hashlib,math
base=Path('/workspace/tam_hawks_ps/.local/legacy-native-current-source/.local/native-01');source=base/'native-result.json';d=json.loads(source.read_text());out={'input_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'scope':'offline arithmetic over immutable native result; no newengine or gameplay','camera_phase_correction':'Historical raw key completed_frame_camera actually samples SceneTree.process_frame signal BEFORE camera._process; first2counterfailures are pre-camera observations, not rendered occlusion certification','cases':[]}
def stats(values):
 v=sorted(values)
 return {'count':len(v),'minimum_m':v[0],'median_m':v[len(v)//2],'p95_m':v[max(0,math.ceil(.95*len(v))-1)],'maximum_m':v[-1]} if v else {'count':0,'unknown':'no native ray in declared range; not clear/support/load proof'}
for c in d['cases']:
 case={'requested_id':c['requested_id'],'guide_verified':c.get('guide_verified'),'guide_source':c.get('guide_source'),'captured_ids':sorted({r['captured_id'] for r in c['rows']}),'native_physics_samples':len(c['rows']),'bails':c['new_bails'],'camera_preupdate_failure_physics':[x['physics'] for x in c['completed_frame_camera'] if not x['clear']],'steady_last8_physics':[r['physics'] for r in c['rows'][-8:]],'unsupported_native_hit_pairs':0,'saturated_native_frames':0}
 for label,rows in [('all',c['rows']),('last8',c['rows'][-8:])]:
  s={}
  for field in ('native_hanger_bearing_gap_samples','native_tyre_vertex_minimum_gap_samples'):
   samples=[g for r in rows for g in r[field]];hit=[x for x in samples if x.get('hit')]
   s[field]={'slots':len(samples),'missing_ray_slots_unknown':len(samples)-len(hit),'signed':stats([g['signed_gap'] for g in hit]),'vertical':stats([g['vertical_gap'] for g in hit]),'minimum_normal_y':min([g['native_normal'][1] for g in hit],default=None),'actual_owners':sorted({g['path'] for g in hit})}
  case[label]=s
 for r in c['rows']:
  found={(h['rid'],h['shape']) for h in r['native_component_hits']};tested={(h['rid'],h['shape']) for h in r['drawn_material_tests']}
  case['unsupported_native_hit_pairs']+=len(found-tested);case['saturated_native_frames']+=r['hit_buffer_saturated_unknown']
 case['last_actual_body']=c['rows'][-1]['actor'];case['last_actual_board']=c['rows'][-1]['board'];out['cases'].append(case)
(base/'gap-derivation.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps([{'requested':c['requested_id'],'late_hanger_signed':c['last8']['native_hanger_bearing_gap_samples']['signed'],'late_tyre_vertical':c['last8']['native_tyre_vertex_minimum_gap_samples']['vertical'],'late_tyre_missing':c['last8']['native_tyre_vertex_minimum_gap_samples']['missing_ray_slots_unknown'],'camera_preupdate_failures':c['camera_preupdate_failure_physics'],'unsupported_native_hit_pairs':c['unsupported_native_hit_pairs']} for c in out['cases']],indent=2))
