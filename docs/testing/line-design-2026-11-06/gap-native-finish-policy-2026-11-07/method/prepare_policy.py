from pathlib import Path
import shutil,hashlib,json,difflib
O=Path(__file__).resolve().parent;P=O/'project';B=O/'pre-policy-sources';B.mkdir(exist_ok=False)
owned=['game/main.gd','game/tricks/gap_tracker.gd','game/levels/glasgow_square.gd','game/levels/outdoor_routes.gd','game/levels/clyde_cable_line.gd']
for n in owned:
 q=B/n;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(P/n,q)
# Direct constructor-held body references, never body-name/metadata searches.
p=P/'game/levels/outdoor_routes.gd';s=p.read_text();s=s.replace('var _sunken_bowls: Array[Node3D] = []','var _sunken_bowls: Array[Node3D] = []\nvar _gap_safe_handrail_bodies: Dictionary = {}')
needle='\t\t\tif not safe:\n\t\t\t\thandrail_body.collision_layer = 1 | 2';assert s.count(needle)==1
s=s.replace(needle,'\t\t\tif safe:\n\t\t\t\tif not _gap_safe_handrail_bodies.has(grind_id): _gap_safe_handrail_bodies[grind_id] = []\n\t\t\t\t_gap_safe_handrail_bodies[grind_id].append(weakref(handrail_body))\n'+needle)
s+='''\n\nfunc gap_grind_destinations() -> Dictionary:
 var result:Dictionary={}
 for id:String in _gap_safe_handrail_bodies:
  var owners:Array=[]
  for body:WeakRef in _gap_safe_handrail_bodies[id]:
   owners.append({"body":body,"shape_indices":PackedInt32Array([0])})
  result[id]={"kind":"handrail","provider":weakref(self),"owners":owners}
 return result
''';p.write_text(s)
p=P/'game/levels/clyde_cable_line.gd';s=p.read_text().replace('var _world: Node3D','var _gap_native_body:WeakRef\nvar _gap_native_shapes:Dictionary={"west":PackedInt32Array(),"east":PackedInt32Array()}\nvar _world: Node3D')
needle='\tadd_child(native)\n\tvar selected := 0';assert s.count(needle)==1;s=s.replace(needle,'\tadd_child(native)\n\t_gap_native_body=weakref(native)\n\tvar selected := 0')
needle='\t\t\tnative.add_child(collision)\n\t\t\tselected += 1';assert s.count(needle)==1;s=s.replace(needle,'\t\t\tnative.add_child(collision)\n\t\t\tvar gap_side:String="west" if side<0.0 else "east"\n\t\t\t_gap_native_shapes[gap_side].append(selected)\n\t\t\tselected += 1')
s=s.replace('"radius":0.7,"points":500,"airborne_required":true})','"radius":0.7,"points":500,"airborne_required":true,"finish_kind":"native_grind",\n\t\t\t"finish_destination":"clyde_cable_"+suffix})',1)
needle='"radius":0.7,"points":500,"airborne_required":true})';assert s.count(needle)==1;s=s.replace(needle,'"radius":0.7,"points":500,"airborne_required":true,"finish_kind":"native_grind",\n\t\t\t"finish_destination":"clyde_safe_handrail_"+suffix})',1)
s+='''\n\nfunc gap_grind_destinations() -> Dictionary:
 var result:Dictionary={}
 for side:String in ["west","east"]:
  result["clyde_cable_"+side]={"kind":"cable","provider":weakref(self),"owners":[{"body":_gap_native_body,"shape_indices":_gap_native_shapes[side].duplicate()}]}
 return result
''';p.write_text(s)
p=P/'game/levels/glasgow_square.gd';s=p.read_text();s+='''\n\nfunc get_gap_grind_destinations() -> Dictionary:
 var result:Dictionary={}
 if is_instance_valid(_outdoors):result.merge(_outdoors.gap_grind_destinations())
 if is_instance_valid(_clyde_cable_line):result.merge(_clyde_cable_line.gap_grind_destinations())
 return result
''';p.write_text(s)
# Legacy configure/update callers stay strict: native policies require a registered destination.
p=P/'game/tricks/gap_tracker.gd';s=p.read_text().replace('func configure(definitions: Array) -> void:','func configure(definitions: Array, native_destinations: PackedStringArray = PackedStringArray()) -> void:')
needle='\t\tvar entry: Dictionary = raw.duplicate(true)';assert s.count(needle)==1
s=s.replace(needle,'''\t\tif raw.has("finish_kind") or raw.has("finish_destination"):
\t\t\tif typeof(raw.get("finish_kind"))!=TYPE_STRING or raw.finish_kind!="native_grind" \\
\t\t\t\tor typeof(raw.get("finish_destination"))!=TYPE_STRING or raw.finish_destination.is_empty() \\
\t\t\t\tor not native_destinations.has(raw.finish_destination) or not raw.airborne_required:
\t\t\t\tcontinue
'''+needle)
s=s.replace('func update(position: Vector3, airborne: bool, delta: float) -> Array[Dictionary]:','func update(position: Vector3, airborne: bool, delta: float, native_finish: Callable = Callable()) -> Array[Dictionary]:')
needle='\t\tvar elapsed_before: float = state.elapsed';assert s.count(needle)==1;s=s.replace(needle,needle+'\n\t\tvar already_armed: bool = state.phase == "armed"')
needle='\t\t\tif ordered and flight_time <= WINDOW and required_air:';assert s.count(needle)==1
s=s.replace(needle,'''\t\t\tif not required_air and already_armed and state.air and air_between and not airborne \\
\t\t\t\tand ordered and flight_time<=WINDOW and definition.get("finish_kind","")=="native_grind" \\
\t\t\t\tand native_finish.is_valid():
\t\t\t\trequired_air=native_finish.call(definition,_previous,position)==true
'''+needle)
p.write_text(s)
p=P/'game/main.gd';s=p.read_text().replace('const GapTrackerSource = preload("res://game/tricks/gap_tracker.gd")','const GapTrackerSource = preload("res://game/tricks/gap_tracker.gd")\nconst NativeGapFinishSource=preload("res://game/tricks/native_gap_finish.gd")').replace('var gaps = GapTrackerSource.new()','var gaps = GapTrackerSource.new()\nvar native_gap_finish=NativeGapFinishSource.new()')
s=s.replace('\tgaps.configure(world.get_gap_definitions())\n','')
needle='\tskater.set_transition_features(world.get_transition_features())';assert s.count(needle)==1;s=s.replace(needle,needle+'\n\tnative_gap_finish.configure(world,skater)\n\tgaps.configure(world.get_gap_definitions(),native_gap_finish.destination_ids())')
s=s.replace('for gap: Dictionary in gaps.update(skater.global_position, skater.airborne, delta):','for gap: Dictionary in gaps.update(skater.global_position, skater.airborne, delta,native_gap_finish.finish):')
needle='\tcat_encounter.on_grind_capture(rail_id, skater.global_position)';assert s.count(needle)==1;s=s.replace(needle,'\tnative_gap_finish.remember_capture(rail_id,gaps._previous,gaps._previous_airborne,gaps._has_previous)\n'+needle)
s=s.replace('func _on_bailed() -> void:\n','func _on_bailed() -> void:\n\tnative_gap_finish.invalidate()\n').replace('func restart_run() -> void:\n','func restart_run() -> void:\n\tnative_gap_finish.invalidate()\n').replace('func toggle_pause() -> void:\n','func toggle_pause() -> void:\n\tnative_gap_finish.invalidate()\n').replace('func _finish_run() -> void:\n','func _finish_run() -> void:\n\tnative_gap_finish.invalidate()\n')
needle='\t_feedback_timer = maxf(0.0, _feedback_timer - delta)';assert s.count(needle)==1;s=s.replace(needle,'\tnative_gap_finish.refresh()\n'+needle)
p.write_text(s)
print('Private policy/provider/Main edits prepared; helper implementation not yet parsed.')
