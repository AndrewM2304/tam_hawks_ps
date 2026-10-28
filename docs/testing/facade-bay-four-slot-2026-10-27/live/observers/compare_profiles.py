#!/usr/bin/env python3
"""Fresh facade comparator. Retains historical audit/data unchanged; no engine."""
import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
from PIL import Image

LABELS = ['spawn','02-frontage-wide','03-frontage-near','exchange_west_bank_loop']
EXPECTED_MESH_ROOT = 'res://game/art/assets/glasgow_bay_reduced_four_slot/'
EXPECTED_TEXTURE_ROOT = 'res://game/art/assets/glasgow_bay/'
ASSET_HASHES = {'near':'67c0ebfbe88f83ddb0108e9c1ba6c861766905c641ed5c72bff102c4d87f8001','mid':'481f8ed518be457a7df00ba720aec75e2dc81351a91b90c2b208c2e370ed7d0c','far':'01347133a605228272dfaa8afefd38dd849e1df183707670b9466f9ff24d64d0'}

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def percentile(values,p):
    values=sorted(values)
    assert values and all(math.isfinite(x) for x in values)
    return values[max(0,min(len(values)-1,math.ceil(len(values)*p)-1))]
def timing_gate(first,candidate,last):
    midpoint=(first+last)/2
    noise=abs(first-last)
    increase=candidate-midpoint
    beyond=increase>noise and increase>midpoint*.05
    worse_cap=candidate<=max(first,last)*1.05
    return {'pass':not beyond and worse_cap,'midpoint_ms':midpoint,'repeat_noise_ms':noise,'candidate_ms':candidate,'increase_ms':increase,'beyond_noise_and_five_percent':beyond,'worse_baseline_cap_ms':max(first,last)*1.05,'worse_baseline_cap_pass':worse_cap}

def self_test():
    assert timing_gate(100,105,100)['pass']
    assert not timing_gate(100,105.00001,100)['pass']
    assert timing_gate(80,125,120)['pass']
    assert not timing_gate(80,126.00001,120)['pass']
    assert timing_gate(100,80,100)['pass']
    assert percentile([3,1,2],.5)==2 and percentile([1,2,3],.95)==3
    assert percentile([1,2,3,4],.5)==2
    print(json.dumps({'comparator_primitive_controls_pass':True,'engine_launched':False}))

def verify(folder,phase,sequence,source):
    receipt_path=folder/'receipt.json'
    receipt=json.loads(receipt_path.read_text())
    assert receipt['acceptance'] and receipt['unchanged'], ('phase receipt rejected',folder)
    assert receipt['source_before']==receipt['source_after'], ('source drift',folder)
    if source is not None: assert receipt['source_before']==source, ('cross-phase source drift',folder)
    source=receipt['source_before']
    for lod,digest in ASSET_HASHES.items():
        assert source['game/art/assets/glasgow_bay_reduced_four_slot/glasgow_bay_'+lod+'.glb']==digest
    assert receipt['probe_before']==receipt['probe_after']
    # Absolute command layout is checked directly against the recorded sequence.
    actual=receipt['command']
    assert actual[-7:] == ['profile',phase['mode'],str(folder),*phase['size'].split('x'),str(float(phase['seconds'])),'balanced'], ('command semantics changed',folder)
    for name,digest in receipt['artifacts'].items():
        path=folder/name
        assert path.is_file() and sha(path)==digest, ('artifact mismatch',path)
    script_arg=Path(phase['command'][phase['command'].index('--script')+1]).resolve()
    runner_arg=Path(phase['command'][1]).resolve()
    assert receipt['probe_before']==sequence['dependencies'][str(script_arg)]
    assert receipt['runner_sha256']==sequence['dependencies'][str(runner_arg)]
    report=json.loads((folder/'report.json').read_text())
    assert report['valid'] and not report['errors'] and report['normal_render_loop'] and not report['fixed_fps']
    assert not report['profile_writes'] and report['mode']=='profile'
    assert report['mesh_root']==EXPECTED_MESH_ROOT and report['texture_root']==EXPECTED_TEXTURE_ROOT
    assert set(report['ordinary_defaults'])=={'main_default','world_default','station','train','pond','civic_return','central_green'}
    assert all(report['ordinary_defaults'].values()), ('ordinary trial content disabled',folder)
    assert report['size']==[int(x) for x in phase['size'].split('x')]
    assert report['pilot_enabled']==(phase['mode']=='on')
    assert len(receipt['pngs'])==4
    for record in receipt['pngs']:
        with Image.open(folder/record['file']) as im:
            im.load()
            assert list(im.size)==record['size']==report['size']
    rows=list(csv.DictReader((folder/'frames.csv').open()))
    summaries=report['stationary_views']+report['moving_trials']
    assert [s.get('id',s.get('route')) for s in summaries]==LABELS
    for index,summary in enumerate(summaries):
        subset=[row for row in rows if row['district']==LABELS[index]]
        assert len(subset)==summary['samples'] and len(subset)>=(10 if index<3 else 3)
        assert all(float(row['frame_ms'])>0 for row in subset)
        for n in [50,95,99]:
            assert abs(percentile([float(row['frame_ms']) for row in subset],n/100)-summary[f'p{n}_ms'])<1e-6
        assert abs(percentile([float(row['draw_calls']) for row in subset],.5)-summary['draw_calls_p50'])<1e-6
        if index<3:
            for key in ['visible_draws','shadow_draws','texture_memory_bytes','buffer_memory_bytes']:
                assert abs(percentile([float(row[key]) for row in subset],.5)-summary[key+'_p50'])<1e-6
    trial=report['moving_trials'][0]
    assert trial['valid_trial'] and not trial['errors'] and trial['bails']==0 and trial['discontinuous_recoveries']==0
    assert trial['distance_m']>=4 and trial['simulated_seconds']>=1 and trial['absolute_turn_radians']>=.08
    assert trial['steering_physics_ticks']>=3 and trial['moving_tick_fraction']>=.6 and trial['maximum_route_deviation_m']<=5.5
    assert trial['requested_sample_seconds']==phase['seconds']*2
    # Carry long-frame and resource distributions as measured; no new admission caps are invented.
    raw={label:{key:percentile([float(row[key]) for row in rows if row['district']==label],.5) for key in ['primitives','video_memory_bytes','texture_memory_bytes','buffer_memory_bytes','render_objects','static_memory_bytes'] if all(row.get(key,'')!='' for row in rows if row['district']==label)} for label in LABELS}
    long_frames={label:{str(limit):sum(float(row['frame_ms'])>limit for row in rows if row['district']==label) for limit in [16.666667,33.333333,50,100]} for label in LABELS}
    return report,source,raw,long_frames

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('sequence',type=Path,nargs='?')
    p.add_argument('--output',type=Path)
    p.add_argument('--self-test',action='store_true')
    a=p.parse_args()
    if a.self_test: self_test(); return 0
    if not a.sequence or not a.output: p.error('sequence.json and --output NEWFILE required')
    if a.output.exists(): p.error('Refusing to overwrite previous comparison.')
    seq=json.loads(a.sequence.read_text());base=a.sequence.resolve().parent
    assert seq['valid'] and len(seq['plan'])==6 and len(seq['completed'])==6
    expected=[(size,label,mode,t) for size,t in [('1280x800',20),('1920x1080',30)] for label,mode in [('a1','off'),('b','on'),('a2','off')]]
    source=None; reports={}; resources={}; longs={}
    for phase,completed,(size,label,mode,t) in zip(seq['plan'],seq['completed'],expected):
        assert phase['name']==size+'-'+label and phase['size']==size and phase['mode']==mode and phase['seconds']==t
        assert completed['name']==phase['name'] and completed['receipt_sha256']==sha(base/phase['name']/'receipt.json')
        report,source,resource,long=verify(base/phase['name'],phase,seq,source)
        reports[phase['name']]=report;resources[phase['name']]=resource;longs[phase['name']]=long
    comparisons=[]
    for size in ['1280x800','1920x1080']:
        first,pilot,last=[reports[size+'-'+label] for label in ['a1','b','a2']]
        assert first['settings']==pilot['settings']==last['settings']
        assert first['device']==pilot['device']==last['device'] and first['renderer']==pilot['renderer']==last['renderer']
        all_summaries=lambda r:r['stationary_views']+r['moving_trials']
        for label,x,y,z in zip(LABELS,all_summaries(first),all_summaries(pilot),all_summaries(last)):
            times={key:timing_gate(x[key],y[key],z[key]) for key in ['p95_ms','p99_ms']}
            delta=y['visible_draws_p50']-max(x['visible_draws_p50'],z['visible_draws_p50']) if 'visible_draws_p50' in y else None
            draw_ok=delta is None or delta<=4
            comparisons.append({'resolution':size,'view':label,'a1':x,'candidate':y,'a2':z,'timing':times,'reported_3d_draw_delta':delta,'draw_gate_pass':draw_ok,'accepted':all(v['pass'] for v in times.values()) and draw_ok})
    passed=all(row['accepted'] for row in comparisons)
    result={'schema':1,'sequence_sha256':sha(a.sequence),'comparator_sha256':sha(Path(__file__)),'source_artifact_png_csv_binding_pass':True,'source_inputs':len(source),'all_six_source_maps_equal':True,'current_ordinary_defaults_on':True,'dataset_count':6,'image_count':24,'gate':'Per view/resolution: p95/p99 may not exceed both baseline repeat noise and 5% midpoint; additionally <=1.05*worse baseline; stationary reported3D delta <=4.','comparisons':comparisons,'resource_medians':resources,'long_frame_counts':longs,'local_timing_budget_pass':passed,'target_mac_acceptance':False,'human_art_acceptance':False,'fps_improvement_claim':False,'historical_rejections_retained':True}
    a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'source_artifact_png_csv_binding_pass':True,'datasets':6,'images':24,'local_timing_budget_pass':passed}))
    return 0 if passed else 1

if __name__=='__main__': raise SystemExit(main())
