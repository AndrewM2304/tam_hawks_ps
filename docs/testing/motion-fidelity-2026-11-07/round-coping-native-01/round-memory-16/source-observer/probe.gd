extends SceneTree
const OldLayout=preload("res://.local/round-memory/legacy_line_layout.gd")
const CurrentLine=preload("res://game/tricks/grind_line.gd")
const Feature=preload("res://game/levels/transition_feature.gd")
const Main=preload("res://game/main.gd")
const COUNT:=256
var feature:Node3D
var points:=PackedVector3Array()
func _initialize()->void:_run.call_deferred()
func _allocation(kind:int)->Dictionary:
 var items:Array=[]
 var before:int=int(Performance.get_monitor(Performance.MEMORY_STATIC))
 for index:int in COUNT:
  var line=OldLayout.new("Grind_RoundMemory_Coping",points) if kind==0 else CurrentLine.new("Grind_RoundMemory_Coping",points)
  line.contact_verified=true
  line.contact_source="feature.native_coping_crown"
  if kind==2:line.configure_round_contact(.03,.012,.010,Vector3.BACK,feature.get_node("NativeSteelCoping"),0)
  items.append(line)
 var after:int=int(Performance.get_monitor(Performance.MEMORY_STATIC))
 var accepted:int=0
 if kind==2:
  for line in items:
   if line.round_contact_live():accepted+=1
 var result:Dictionary={"kind":kind,"count":COUNT,"before":before,"retained":after-before,"per_line":float(after-before)/COUNT,"live_profiles":accepted}
 items.clear()
 return result
func _run()->void:
 feature=Feature.new()
 feature.feature_id="RoundMemory"
 feature.position.y=70
 feature.width=8
 feature.build_access=false
 root.add_child(feature)
 await physics_frame
 await physics_frame
 var actual=feature.get_grind_lines()[0]
 points=actual.points
 var samples:Array=[]
 for cycle:int in 5:
  for kind:int in [0,1,2]:
   var sample:Dictionary=_allocation(kind)
   sample.cycle=cycle
   print("ROUND_MEMORY_SAMPLE ",JSON.stringify(sample))
   samples.append(sample)
 var game:Node=Main.new()
 game.persistence_enabled=false
 game.set_meta("pt24_design_preview",false)
 root.add_child(game)
 for tick:int in 35:
  await physics_frame
  await process_frame
 var total:int=0
 var round_profiles:int=0
 var max_round_cell:int=0
 var max_cell:int=0
 for line in game.skater._grind_lines:
  total+=1
  if line.contact_round_declared:round_profiles+=1
 for cell:Array in game.skater._grind_index._cells.values():
  max_cell=maxi(max_cell,cell.size())
  var round_count:int=0
  for line in cell:
   if line.contact_round_declared:round_count+=1
  max_round_cell=maxi(max_round_cell,round_count)
 print("ROUND_MEMORY_RESULT ",JSON.stringify({"samples":samples,"legacyMainGuides":total,"round_profiles":round_profiles,"maximum_round_profiles_per_index_cell":max_round_cell,"maximum_all_guides_per_index_cell":max_cell,"scope":"native allocator retained-byte component diagnostic; no elapsed/performance/M5 claim"}))
 quit(0)
