from pathlib import Path
import json,hashlib
O=Path(__file__).resolve().parent
MAX_SCORE=2147483647;MAX_EVENT=1000000;MULT_LIMIT=100;HALF_LIMIT=4

def score_ledger(data):
 total=base=count=lastentry=lastrepeats=0;lastid='';reps={};mismatches=[];runs={};ledger=[]
 def state():return {'total':total,'base':base,'multiplier':min(count,MULT_LIMIT),'value':min(MAX_SCORE,base*min(count,MULT_LIMIT))}
 kinds={'add_trick','add_hold_points','add_spin_bonus','upgrade_last_trick','bank_combo','drop_combo','reset'}
 for i,e in enumerate(data['score_events']):
  kind=e['kind']
  if kind not in kinds:continue
  before=state();run=runs.setdefault(e['run'],{'mutating_calls':0,'positive_banks':[],'drops':0,'entry_awards':[],'bonus_awards':[]});run['mutating_calls']+=1
  for k,v in before.items():
   if e['before'][k]!=v:mismatches.append({'index':i,'run':e['run'],'kind':kind,'where':'before','field':k,'expected':v,'observed':e['before'][k]})
  award=None
  if kind=='reset':total=base=count=lastentry=lastrepeats=0;lastid='';reps={}
  elif kind in ('bank_combo','drop_combo'):
   value=before['value']
   if kind=='bank_combo':
    if e['banked']!=value:mismatches.append({'index':i,'kind':kind,'expected_banked':value,'observed':e['banked']})
    total=min(MAX_SCORE,total+value)
    if value>0:run['positive_banks'].append({'physics':e['physics'],'base':base,'multiplier':min(count,MULT_LIMIT),'value':value})
   else:run['drops']+=1
   base=count=lastentry=lastrepeats=0;lastid=''
  elif kind=='add_trick':
   key=e['identity'].strip()or e['label'];n=reps.get(key,0)
   points=max(1,min(e['points'],MAX_EVENT)//(2**min(max(n,0),HALF_LIMIT)))
   old=base;base=min(MAX_SCORE,base+points);award=base-old
   count=min(MAX_SCORE,count+1);lastid=key;lastrepeats=n;lastentry=award;reps[key]=min(n+1,HALF_LIMIT)
   run['entry_awards'].append({'physics':e['physics'],'identity':key,'source_points':e['points'],'repetitions_before':n,'award':award})
  elif kind in ('add_hold_points','add_spin_bonus'):
   old=base
   if count>0 and before['value']>0 and e['points']>0:base=min(MAX_SCORE,base+min(e['points'],MAX_EVENT))
   award=base-old;run['bonus_awards'].append({'physics':e['physics'],'kind':kind,'source_points':e['points'],'award':award})
  elif kind=='upgrade_last_trick':
   if lastrepeats==0:reps.pop(lastid,None)
   else:reps[lastid]=lastrepeats
   key=e['identity'].strip()or e['label'];n=reps.get(key,0)
   points=max(1,min(e['points'],MAX_EVENT)//(2**min(max(n,0),HALF_LIMIT)))
   old=base;without=max(0,base-lastentry);base=min(MAX_SCORE,without+points);award=base-old
   lastid=key;lastrepeats=n;lastentry=base-without;reps[key]=min(n+1,HALF_LIMIT)
  after=state()
  for k,v in after.items():
   if e['after'][k]!=v:mismatches.append({'index':i,'run':e['run'],'kind':kind,'where':'after','field':k,'expected':v,'observed':e['after'][k]})
  if award is not None and award!=e['awarded']:mismatches.append({'index':i,'kind':kind,'expected_award':award,'observed':e['awarded']})
  ledger.append({'source_event_index':i,'run':e['run'],'physics':e['physics'],'kind':kind,'before':before,'after':after,'independent_award':award})
 return {'method':'Independent Python integer replay of source point inputs, stable IDs, repeated halving floor/saturation, bonuses, upgrades and score/multiplier caps. Skips nonmutating landing/continue events including nested callbacks; does not trust returned awards/bases as inputs. Resets and bank/drop boundaries remain independent.','mismatches':mismatches,'runs':runs,'ledger':ledger}

def main():
 a=json.loads((O/'policy-matched-off-01/native-result.json').read_text());b=json.loads((O/'policy-matched-on-01/native-result.json').read_text())
 ma=json.loads((O/'policy-matched-off-01/source-before.json').read_text());mb=json.loads((O/'policy-matched-on-01/source-before.json').read_text())
 keys=['run','tick','stage','physics','position','airborne','grinding','grind_id','floor','last_gap_call']
 physical=[]
 for i,(x,y)in enumerate(zip(a['samples'],b['samples'])):
  for k in keys:
   if x[k]!=y[k]:physical.append({'index':i,'key':k,'off':x[k],'on':y[k]})
 rowkeys=['run','physics','position','previous','previous_sample_frame','has_previous','previous_airborne','airborne','delta','grinding','grind_id','is_on_floor','velocity','speed','phase_before','phase_after','legacy_awards']
 for i,(x,y)in enumerate(zip(a['gap_updates'],b['gap_updates'])):
  for k in rowkeys:
   if x[k]!=y[k]:physical.append({'gap_index':i,'key':k,'off':x[k],'on':y[k]})
 scores={'off':score_ledger(a),'on':score_ledger(b)}
 extra=[{'run':e['run'],'physics':e['physics'],'award':w}for e in b['gap_updates']for w in e['awards']if not any(w in z['awards']and z['run']==e['run']and z['physics']==e['physics']for z in a['gap_updates'])]
 result={'source_manifests_identical':ma==mb,'source_count':len(ma),'sample_counts':[len(a['samples']),len(b['samples'])],'gap_counts':[len(a['gap_updates']),len(b['gap_updates'])],'physical_sample_keys':keys,'physical_gap_keys':rowkeys,'physical_mismatches':physical,'additional_awards':extra,'native_queries':{'off':a['native_finish_queries'],'on':b['native_finish_queries']},'scores':scores,'scope':'Matched identical-source natural mapped-input six-case A/B; test wrapper only switches passed finish Callable. Comparison excludes process counters/render timing and score fields by design. No visual, full body contact, M5/performance or cross-area circuit acceptance.'}
 result['passed']=ma==mb and len(a['samples'])==len(b['samples'])and len(a['gap_updates'])==len(b['gap_updates'])and not physical and not scores['off']['mismatches']and not scores['on']['mismatches']and len(extra)==2 and all(e['award']['id'].startswith('clyde_cable_to_handrail_')and e['award']['points']==500 for e in extra)
 (O/'matched-comparison-01.json').write_text(json.dumps(result,indent=2)+'\n')
 print(json.dumps({k:v for k,v in result.items()if k!='scores'},indent=2))
 print(json.dumps({mode:{'mismatches':s['mismatches'],'runs':s['runs']}for mode,s in scores.items()},indent=2))
if __name__=='__main__':main()
