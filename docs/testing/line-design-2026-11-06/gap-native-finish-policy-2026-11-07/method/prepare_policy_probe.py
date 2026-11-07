from pathlib import Path
O=Path(__file__).resolve().parent;P=O/'project'
p=P/'game/tricks/native_gap_finish.gd';s=p.read_text().replace('proof_events.append(','_record_proof(')
s+='''\nfunc _record_proof(event:Dictionary)->void:
 proof_events.append(event)
 if proof_events.size()>64:proof_events.pop_front()
''';p.write_text(s)
legacy=(O/'pre-policy-sources/game/tricks/gap_tracker.gd').read_bytes();(P/'.local/gap_tracker_legacy.gd').write_bytes(legacy)
gap=(P/'.local/gap_observer.gd').read_text();gap=gap.replace('const Original=preload("res://game/tricks/gap_tracker.gd")','const Original=preload("res://.local/gap_tracker_legacy.gd")').replace('var mismatches:Array=[]','var mismatches:Array=[]\nvar policy_deltas:Array=[]')
gap=gap.replace('func configure(definitions:Array)->void:\n super.configure(definitions)','func configure(definitions:Array,native_destinations:PackedStringArray=PackedStringArray())->void:\n super.configure(definitions,native_destinations)')
gap=gap.replace('func update(position:Vector3,airborne:bool,delta:float)->Array[Dictionary]:','func update(position:Vector3,airborne:bool,delta:float,native_finish:Callable=Callable())->Array[Dictionary]:').replace('super.update(position,airborne,delta)','super.update(position,airborne,delta,native_finish)')
gap=gap.replace('if awards!=expected or _states!=shadow._states','''var missing:Array=[]
 for old_award:Dictionary in expected:
  if not awards.has(old_award):missing.append(old_award)
 var added:Array=[]
 for award:Dictionary in awards:
  if not expected.has(award):added.append(award)
 if not added.is_empty():policy_deltas.append({"physics":Engine.get_physics_frames(),"run":run_label,"added":added,"legacy":expected.duplicate(true),"new":awards.duplicate(true)})
 if not missing.is_empty() or _states!=shadow._states''')
gap=gap.replace('"awards":awards.duplicate(true)','"awards":awards.duplicate(true),"legacy_awards":expected.duplicate(true)')
(P/'.local/gap_policy_observer.gd').write_text(gap)
probe=(P/'.local/probe.gd').read_text().replace('const Cable=preload("res://tests/clyde_cable_line_tests.gd")','const CableWest=preload("res://.local/cable_timing_driver.gd")\nconst CableEast=preload("res://.local/cable_east_driver.gd")\nconst LegacyTests=preload("res://tests/special_gap_tests.gd")').replace('const GapObserver=preload("res://.local/gap_observer.gd")','const GapObserver=preload("res://.local/gap_policy_observer.gd")')
probe=probe.replace(' game=Main.new()',' LegacyTests.run(check)\n game=Main.new()',1)
a=''' for direction:float in [1.0,-1.0]:
  gap_probe.run_label="west_southbound"if direction>0.0 else"west_northbound"
  score_probe.run_label=gap_probe.run_label
  await Cable._drive_player(self,game,check,direction,observe)'''
b=''' check(game.native_gap_finish.ready,"native destinations configure from real constructor-owned bodies and actual Skater lines")
 check(game.gaps._definitions.size()==8,"all eight original gap IDs retain registered strict or native-finish definitions")
 for entry:Dictionary in [{"run":"west_south_wait_12","east":false,"direction":1.0,"wait":12},{"run":"east_south_wait_12","east":true,"direction":1.0,"wait":12},{"run":"west_south_original","east":false,"direction":1.0,"wait":0},{"run":"east_south_original","east":true,"direction":1.0,"wait":0},{"run":"west_north_original","east":false,"direction":-1.0,"wait":0},{"run":"east_north_original","east":true,"direction":-1.0,"wait":0}]:
  gap_probe.run_label=str(entry.run)
  score_probe.run_label=gap_probe.run_label
  if bool(entry.east):
   CableEast.extra_cable_wait=int(entry.wait)
   await CableEast._drive_player(self,game,check,float(entry.direction),observe)
  else:
   CableWest.extra_cable_wait=int(entry.wait)
   await CableWest._drive_player(self,game,check,float(entry.direction),observe)
 var ids:Array=[]
 for row:Dictionary in gap_probe.rows:
  for award:Dictionary in row.awards:
   if not ids.has(award.id):ids.append(award.id)
 check(ids.has("clyde_handrail_to_cable_west")and ids.has("clyde_cable_to_handrail_west")and ids.has("clyde_handrail_to_cable_east")and ids.has("clyde_cable_to_handrail_east"),"all four original scored cable IDs award through actual mapped input/native captures")'''
assert a in probe;probe=probe.replace(a,b).replace('"super-delegating tracker returns exact original awards/state every actual update"','"legacy awards and every tracker phase remain exact; explicit destination policy may only add finish awards"')
probe=probe.replace('"shadow_mismatches":gap_probe.mismatches','"shadow_mismatches":gap_probe.mismatches,"policy_deltas":gap_probe.policy_deltas,"native_finish_ready":game.native_gap_finish.ready,"native_finish_rejection":game.native_gap_finish.rejection,"native_finish_queries":game.native_gap_finish.native_queries,"native_finish_events":encode(game.native_gap_finish.proof_events)')
probe=probe.replace('Original WEST two-direction mapped-input driver unchanged; only initial spawn/orientation per production test.','PRIVATE native destination-policy positive: unchanged old special/gap unit tests plusWEST/EASTsouthWAIT12 and originaltiming both directions; explicitmirror/inputwait fixtures. No physical pose/velocity/heading/score writes afterinitialspawn.')
(P/'.local/probe_policy.gd').write_text(probe)
runner=(O/'run.py').read_text().replace("OUT=O/'west-native-01'","OUT=O/'policy-positive-01'").replace("['probe.gd','gap_observer.gd','score_observer.gd']","['probe_policy.gd','gap_policy_observer.gd','gap_tracker_legacy.gd','cable_timing_driver.gd','cable_east_driver.gd','score_observer.gd']").replace('res://.local/probe.gd','res://.local/probe_policy.gd').replace('original WEST±cable inputs unchanged','PRIVATE explicitnativefinishpolicy; WEST/EASTsouthWAIT12 and originaltiming±driver')
(O/'run_policy.py').write_text(runner)
print('Private positive policy probe prepared; no engine started.')
