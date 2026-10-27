import json,sys,re,math
from pathlib import Path
root=Path.cwd()
before=json.loads((root/'.local/active_wall_arm_before_proof_v3.json').read_text())
after=json.loads((root/'.local/active_wall_arm_candidate_proof_v3.json').read_text())
checks=[]
def check(ok,label):
 checks.append({'ok':bool(ok),'label':label});print(('PASS: ' if ok else 'FAIL: ')+label)
check(before['native_workload_valid'] and after['native_workload_valid'] and before['contact_tick']==after['contact_tick']==58 and before['active_flip_ticks']==after['active_flip_ticks']>=15,'real native approach, caught shutter, Ollie and fresh Flip remain deterministic')
check(before['entries']==after['entries'] and before['banks']==after['banks']==[800] and before['score_total']==after['score_total']==800,'unchanged native trick/landing signals bank exact two-entry800 once')
a=before['samples'];b=after['samples'];same=len(a)==len(b)
fields=['phase','tick','body','velocity','visual','offset','deck','rider','nonarm_bones','grab_remaining','grab_blend','active_flip','airborne','on_floor','bailing','speed']
check(same and all(all(x[k]==y[k] for k in fields) for x,y in zip(a,b)),'all physical state, shared root, board/rider and every non-arm bone stay identical')
check(same and all(all(x['arms'][1][k]==y['arms'][1][k] for k in ['shoulder','elbow','wrist','upper_length','lower_length']) for x,y in zip(a,b)),'far unblocked arm stays identical')
check(all(abs(r['upper_length']-.30)<.00001 and abs(r['lower_length']-.29)<.00001 for s in b for r in s['arms']),'both original fixed .30/.29 arm lengths remain exact')
check(all(r['envelope_misses']==0 for s in b for r in s['arms']),'cached affine row/curl envelopes contain every original native Skin and hand vertex')
first=next((i for i,s in enumerate(b) if s['candidate'].get('accepted',0)>0),None)
check(first is not None and all(r['native_panel_sleeve_vertices_within_skin']==0 and r['native_panel_hand_vertices_within_skin']==0 for s in b[first:] for r in s['arms']),'every sleeve/hand vertex retains existing8mm finite panel skin from first correction through catch/landing/release')
# AuthenticPose's220mm criterion has a fixed body. Compare actual pose
# markers in the native actor frame; retain world-motion metrics separately.
def vec(s):return tuple(map(float,re.findall(r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?',s)))
def distance(x,y):return math.sqrt(sum((a-b)**2 for a,b in zip(vec(x),vec(y))))
changed=[[any(x['arms'][j][k]!=y['arms'][j][k] for k in ['elbow','wrist']) for j in range(2)] for x,y in zip(a,b)]
steps=[distance(b[i]['markers_body'][j+3],b[i-1]['markers_body'][j+3]) for i in range(1,len(b)) for j in range(2) if changed[i][j] or changed[i-1][j]]
check(bool(steps) and max(steps)<.22 and after['maximum_body_marker_step']<.22,'unchanged220mm fixed-body pose criterion holds for all actual native body-relative markers and changed-hand transitions')
unchanged=all(all(x['markers_world'][j]==y['markers_world'][j] and x['markers_body'][j]==y['markers_body'][j] for j in range(5) if j<3 or not changed[i][j-3]) for i,(x,y) in enumerate(zip(a,b)))
check(unchanged,'every unmodified head/foot/hand marker matches baseline exactly in world and body coordinates')
print('WORLD_MOTION_BASELINE',before['maximum_marker_step'],'CANDIDATE',after['maximum_marker_step'],'BODY_POSE_BASELINE',before['maximum_body_marker_step'],'CANDIDATE',after['maximum_body_marker_step'],'CHANGED_BODY_WRIST_MAX',max(steps) if steps else None)
check(all(s['cloth']['finite'] and s['cloth']['seam']<.12 and s['cloth']['joint_gap']<.10 and s['cloth']['neck_gap']<.05 for s in b),'original real Skin waist/neck attachment bounds remain intact')
report=after['candidate']
check(report.get('query_restored') and report['maximum_calls']<=12 and report['maximum_shift']<=.20,'all reused query fields restore, at most12 native calls and20cm free-wrist correction')
result={'passed':sum(x['ok'] for x in checks),'failed':sum(not x['ok'] for x in checks),'checks':checks,'candidate':report,'maximum_marker_step':after['maximum_marker_step'],'first_corrected_sample':first,'baseline_global_marker':before['maximum_marker_step'],'baseline_body_pose_marker':before['maximum_body_marker_step'],'candidate_body_pose_marker':after['maximum_body_marker_step'],'changed_wrist_maximum':max(steps) if steps else None,'scope':'First paired actual ServiceGate native history only. Corner/removed-wall/unsafe bounds, grip/native regression and matched rendered acceptance remain separate.'}
(root/'.local/active_wall_arm_comparison_v3.json').write_text(json.dumps(result,indent=2)+'\n')
print('RESULT:',result['passed'],'passed,',result['failed'],'failed')
raise SystemExit(1 if result['failed'] else 0)
