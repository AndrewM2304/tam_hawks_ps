extends SceneTree
const Manual=preload("res://tests/skater_wall_manual_tests.gd")
const Arms=preload("res://tests/skater_obstacle_arm_tests.gd")
var passed:=0
var failures: Array[String]=[]
var module:=""
var modules: Array[Dictionary]=[]
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	for name: String in ["entire_skater_wall_manual_tests","entire_skater_obstacle_arm_tests"]:
		module=name
		var before:=passed
		var old_failures:=failures.size()
		if name=="entire_skater_wall_manual_tests":await Manual.run(self,_check)
		else:await Arms.run(self,_check)
		modules.append({"name":name,"passes":passed-before,"failures":failures.size()-old_failures})
	var out:=FileAccess.open(OS.get_environment("TAM_DEFORMED_EVIDENCE_DIR")+"/result.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"scope":"complete current WallManual.run and ObstacleArm.run on actual production source; QA-reviewed shader-correct witness and declared+8mm initial fixture phase, original inputs/assertions/thresholds/twins preserved; no performance/M5 claim",
		"passes":passed,"failures":failures,"modules":modules},"\t")+"\n")
	out.close()
	print("CURRENT_CONTACT_RESULT ",passed,"/",failures.size())
	quit(0 if failures.is_empty() else 1)
func _check(ok: bool,label: String) -> void:
	if ok:passed+=1;print("PASS ",label)
	else:failures.append(module+": "+label);print("FAIL ",label)
