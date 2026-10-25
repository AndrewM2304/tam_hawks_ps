extends SceneTree
const Suite = preload("res://tests/run_tests.gd")
const Surfaces = preload("res://tests/surface_coverage_tests.gd")
var game: Node
var passed := 0
var failed := 0
func _initialize(): call_deferred("_run")
func _check(ok: bool,label: String):
 if ok: passed+=1
 else:
  failed+=1
  push_error("FAIL: "+label)
func _boundary(stage: String):
 var world: Node3D=game.world
 var audit: Dictionary=world.get_surface_audit()
 var valid := true
 for record: Dictionary in audit.surfaces:
  var body: StaticBody3D=world.get_node(NodePath(record.path))
  if body.get_meta("exploration_boundary",false):
   var matches := true
   if body.get_meta("boundary_family","")=="SouthPocketRearBoundary":
    matches=record.wallrideable and body.get_meta("solid_boundary",false) and not body.get_meta("no_wallride",true) and Surfaces._printyard_wall_backed(world,body)
   else:
    matches=not record.wallrideable and body.get_meta("no_wallride",false)
   if not matches: print("PREFIX_BOUNDARY_BAD stage=",stage," record=",record)
   valid=valid and matches
 print("PREFIX_STAGE ",stage," boundary=",valid," checks=",passed,"/",failed)
func _physics_frames(count: int):
 for frame in count:
  await physics_frame
  await process_frame
func _run():
 game = preload("res://game/main.gd").new()
 game.persistence_enabled=false
 root.add_child(game)
 await _physics_frames(35)
 _boundary("INITIAL")
 await Suite.HORIZON_TESTS.run(self, game.world, _check)
 _boundary("HORIZON_TESTS")
 await Suite.PT24_BOUNDARY_TESTS.run(self,game.world,_check)
 _boundary("PT24_BOUNDARY_TESTS")
 await Suite.PT24_CITY_REPAIRS_TESTS.run(self,game,_check)
 _boundary("PT24_CITY_REPAIRS_TESTS")
 await Suite.MERCHANT_RETURN_TESTS.run(self,game,_check)
 _boundary("MERCHANT_RETURN_TESTS")
 await Suite.PARK_CONSTRUCTION_TESTS.run(self,game,_check)
 _boundary("PARK_CONSTRUCTION_TESTS")
 await Suite.STATION_GATE_REPAIRS.run(self,game,_check)
 _boundary("STATION_GATE_REPAIRS")
 await Suite.PT24_RENDER_REPAIRS_TESTS.run(self,game.world,_check)
 _boundary("PT24_RENDER_REPAIRS_TESTS")
 await Suite.PT24_CONNECTED_RUNS_TESTS.run(self,game,_check)
 _boundary("PT24_CONNECTED_RUNS_TESTS")
 await Suite.STATION_RAILWAY_TESTS.run(self,game,_check)
 _boundary("STATION_RAILWAY_TESTS")
 await Suite.CLYDE_CABLE_LINE_TESTS.run_player(self,game,_check)
 _boundary("CLYDE_CABLE_LINE_TESTS")
 await Suite.PT24_CIVIC_FLAGSHIP_TESTS.run(self,game,_check)
 _boundary("PT24_CIVIC_FLAGSHIP_TESTS")
 await Suite.PT24_FLAGSHIP_RUNS_TESTS.run(self,game,_check)
 _boundary("PT24_FLAGSHIP_RUNS_TESTS")
 await Suite.PT24_CLYDE_FLAGSHIP_TESTS.run(self,game,_check)
 _boundary("PT24_CLYDE_FLAGSHIP_TESTS")
 await Suite.PT24_PARK_RUN_TESTS.run(self,game,_check)
 _boundary("PT24_PARK_RUN_TESTS")
 await Suite.MAP_CONNECTOR_TESTS.run(self, game.world, _check)
 _boundary("MAP_CONNECTOR_TESTS")
 await Suite.COMPACT_CLYDE_TESTS.run(self, game.world, _check)
 _boundary("COMPACT_CLYDE_TESTS")
 await Suite.WORLD_ROUTES_TESTS.run(self, game.world, _check)
 _boundary("WORLD_ROUTES_TESTS")
 Suite.GRIND_CONTACT_METADATA_TESTS.run_world(game.world,_check)
 _boundary("GRIND_CONTACT_METADATA_TESTS")
 await Suite.SKATE_EDGES_TESTS.run(game.world, _check)
 _boundary("SKATE_EDGES_TESTS")
 await Suite.SUPPORT_QUERY_TESTS.run(game.world, _check)
 _boundary("SUPPORT_QUERY_TESTS")
 Suite.ENVIRONMENT_TEXT_TESTS.run(self, game, _check)
 _boundary("ENVIRONMENT_TEXT_TESTS")
 Suite.GLASGOW_MURALS_TESTS.run(game.world, _check)
 _boundary("GLASGOW_MURALS_TESTS")
 await Suite.SURFACE_COVERAGE_TESTS.run(self, game.world, _check)
 _boundary("SURFACE_COVERAGE_TESTS")
 game.queue_free()
 await physics_frame
 print("RESULT: %d passed, %d failed"%[passed,failed])
 quit(1 if failed else 0)
