#!/usr/bin/env python3
"""Independently check frozen receipts, decoded images, CSV quantiles and budgets."""
import csv
import hashlib
import json
import math
from pathlib import Path
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
DATA=HERE/'measurements'

def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
paths=[ROOT/'project.godot']
for directory in ('game','assets','tests','tools'):
 paths.extend(p for p in (ROOT/directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts)
CURRENT={str(p.relative_to(ROOT)):digest(p) for p in sorted(paths)}
normalizations=[]
# Retain byte-exact executed scripts. Only these explicit post-measurement
# clarifications are allowed; no rendering, physics or measurement logic drift.
for name,archive,old,new,reason in [
 ('tools/facade_bay_probe.gd','frozen-probe.gd.txt',
  'Counters distinguish visible and shadow work.',
  'Reported3D counters include shadow work; Compatibility does not separate shadow submissions.',
  'Correct one report-only limitation sentence after the frozen measurements.'),
 ('game/levels/art/facade_bay.gd','frozen-facade-bay.gd.txt',
  'const DEFAULT_ENABLED := true # One bounded pilot; retain only after matched acceptance.',
  'const DEFAULT_ENABLED := false # Held back by the matched frame-time gate.',
  'Disable normal-play default if the candidate fails; explicit probe on/off overrides are unchanged.')]:
 frozen=(HERE/archive).read_bytes()
 current=(ROOT/name).read_bytes()
 assert frozen.count(old.encode())==1
 assert current in (frozen,frozen.replace(old.encode(),new.encode())), name
 if current!=frozen:
  normalizations.append({'path':name,'executed_sha256':hashlib.sha256(frozen).hexdigest(),
   'current_sha256':digest(ROOT/name),'reason':reason,'only_exact_text_change_verified':True})
 CURRENT[name]=hashlib.sha256(frozen).hexdigest()
def percentile(values,p):
 values=sorted(values)
 return values[max(0,min(len(values)-1,math.ceil(len(values)*p)-1))]

def verify(folder):
 receipt=json.loads((folder/'receipt.json').read_text())
 assert receipt['acceptance'] and receipt['unchanged'], folder
 assert receipt['source_before']==receipt['source_after'], folder
 assert receipt['source_before']==CURRENT, folder
 assert all(digest(folder/f)==sha for f,sha in receipt['artifacts'].items()), folder
 report=json.loads((folder/'report.json').read_text())
 assert report['valid'] and not report['errors'] and report['normal_render_loop'] and not report['fixed_fps'], folder
 assert not report['profile_writes'], folder
 for record in receipt['pngs']:
  with Image.open(folder/record['file']) as image:
   image.load()
   assert list(image.size)==record['size']==report['size'], folder
 if report['mode']=='profile':
  rows=list(csv.DictReader((folder/'frames.csv').open()))
  expected=['spawn','02-frontage-wide','03-frontage-near','exchange_west_bank_loop']
  assert [s.get('id',s.get('route')) for s in report['stationary_views']+report['moving_trials']]==expected, folder
  for summary in report['stationary_views']+report['moving_trials']:
   label=summary.get('id',summary.get('route'))
   subset=[r for r in rows if r['district']==label]
   assert len(subset)==summary['samples'] and len(subset)>=10, (folder,label)
   for p in [50,95,99]:
    assert abs(percentile([float(r['frame_ms']) for r in subset],p/100)-summary[f'p{p}_ms'])<1e-6,(folder,label,p)
   assert abs(percentile([float(r['draw_calls']) for r in subset],.5)-summary['draw_calls_p50'])<1e-6
  assert all(t['valid_trial'] and t['bails']==0 and t['discontinuous_recoveries']==0 for t in report['moving_trials'])
 return report

reports={folder.name:verify(folder) for folder in sorted(DATA.iterdir()) if folder.is_dir()}
rows=[]
passes=True
for suffix in ['', '-1080']:
 a1,b,a2=[reports['shadow-'+label+suffix] for label in ['a1','b','a2']]
 assert not a1['pilot_enabled'] and b['pilot_enabled'] and not a2['pilot_enabled']
 assert a1['settings']==b['settings']==a2['settings'] and a1['size']==b['size']==a2['size']
 assert a1['device']==b['device']==a2['device'] and a1['renderer']==b['renderer']==a2['renderer']
 combined=lambda r:r['stationary_views']+r['moving_trials']
 for first,pilot,last in zip(combined(a1),combined(b),combined(a2)):
  label=pilot.get('id',pilot.get('route'))
  # Reject an increase exceeding BOTH baseline repeat noise and 5% of the
  # baseline midpoint. Also cap at 5% above the worse baseline. These short
  # software-rendered trials cannot establish significance or target FPS.
  timing={}
  timing_details={}
  for key in ['p95_ms','p99_ms']:
   midpoint=(first[key]+last[key])/2
   noise=abs(first[key]-last[key])
   increase=pilot[key]-midpoint
   beyond_noise_and_five=increase>noise and increase>midpoint*.05
   worse_baseline_cap=pilot[key]<=max(first[key],last[key])*1.05
   timing[key]=not beyond_noise_and_five and worse_baseline_cap
   timing_details[key]={'baseline_midpoint_ms':midpoint,'repeat_noise_ms':noise,
    'increase_ms':increase,'beyond_noise_and_five_percent':beyond_noise_and_five,'worse_baseline_cap_pass':worse_baseline_cap}
  draw_delta=None
  if 'visible_draws_p50' in pilot:
   draw_delta=pilot['visible_draws_p50']-max(first['visible_draws_p50'],last['visible_draws_p50'])
  draw_ok=draw_delta is None or draw_delta<=4
  passed=all(timing.values()) and draw_ok
  passes=passes and passed
  rows.append({'resolution':a1['size'],'view':label,'baseline_a1':first,'pilot_b':pilot,'baseline_a2':last,
   'reported_3d_draw_delta':draw_delta,'draw_gate_pass':draw_ok,'timing_gate_pass':timing,'timing_details':timing_details,'accepted':passed})
assert not any(n['path']=='game/levels/art/facade_bay.gd' for n in normalizations) or not passes
result={'auditor_sha256':digest(Path(__file__)),'frozen_source_verified':True,'executed_source_checkpoint':'c2e86ab',
 'post_measurement_changes':normalizations,'dataset_count':len(reports),'image_count':sum(len(list((DATA/name).glob('*.png'))) for name in reports),
 'local_pilot_budget_pass':passes,'gate':'Reject p95/p99 increase exceeding BOTH peak-to-peak baseline repeat noise and 5% of baseline midpoint; also cap at 1.05 * worse baseline. Reported stationary3D draw delta <=4.',
 'shadow_counter_note':'Compatibility reports zero in separate SHADOW counter despite real shadows; reported3D and total counters are not isolated main-pass counts.',
 'target_mac_acceptance':False,'fps_improvement_claim':False,'comparisons':rows}
(HERE/'audit.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({'datasets':len(reports),'images':result['image_count'],'local_pilot_budget_pass':passes}))
raise SystemExit(0 if passes else 1)
