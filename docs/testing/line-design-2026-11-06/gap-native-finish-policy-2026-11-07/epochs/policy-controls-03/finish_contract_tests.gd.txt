extends RefCounted
const Tracker=preload("res://game/tricks/gap_tracker.gd")
static func definition()->Dictionary:
 return {"id":"fixture_finish","name":"Fixture Finish","start":Vector3.ZERO,"end":Vector3(3,0,0),"radius":0.3,"points":500,"airborne_required":true,"finish_kind":"native_grind","finish_destination":"fixture_rail"}
static func run(check:Callable)->void:
 var source:Dictionary=definition()
 var ids:=PackedStringArray(["fixture_rail"])
 for patch:Dictionary in [{"finish_kind":"unknown"},{"finish_kind":null},{"finish_destination":""},{"finish_destination":5},{"finish_destination":"unregistered"},{"airborne_required":false}]:
  var malformed:Dictionary=source.duplicate(true);malformed.merge(patch,true)
  var tracker:=Tracker.new();tracker.configure([malformed],ids)
  check.call(tracker._definitions.is_empty(),"native finish schema refuses present invalid policy "+str(patch))
 var unregistered:=Tracker.new();unregistered.configure([source])
 check.call(unregistered._definitions.is_empty(),"native finish requires an explicitly registered authored destination")
 var generic:Dictionary=source.duplicate(true);generic.erase("finish_kind");generic.erase("finish_destination")
 var calls:Dictionary={"count":0}
 var callback:Callable=func(_d:Dictionary,_a:Vector3,_b:Vector3,_frame:int)->bool:calls.count+=1;return true
 var strict:=Tracker.new();strict.configure([generic]);strict.update(Vector3(-1,0,0),true,.1);strict.update(Vector3.ZERO,true,.1)
 check.call(strict.update(Vector3(3,0,0),false,.2,callback).is_empty()and calls.count==0,"generic grounded finish remains strict even with a deceptive true callback")
 var missing:=Tracker.new();missing.configure([source],ids);missing.update(Vector3(-1,0,0),true,.1);missing.update(Vector3.ZERO,true,.1)
 check.call(missing.update(Vector3(3,0,0),false,.2).is_empty(),"legacy three-argument update never acquires a native finish implicitly")
 var roll:=Tracker.new();roll.configure([source],ids);roll.update(Vector3(-1,0,0),false,.1);roll.update(Vector3.ZERO,false,.1)
 check.call(roll.update(Vector3(3,0,0),false,.2,callback).is_empty()and calls.count==0,"ground roll never calls destination authority")
 var first:=Tracker.new();first.configure([source],ids)
 check.call(first.update(Vector3(3,0,0),false,.1,callback).is_empty()and calls.count==0,"new first sample cannot finish a gap")
 var same:=Tracker.new();same.configure([source],ids);same.update(Vector3(-1,0,0),true,.1)
 check.call(same.update(Vector3(3,0,0),false,.2,callback).is_empty()and calls.count==0,"newly armed one-step nonair capture cannot invent prior gap air")
 var expired:=Tracker.new();expired.configure([source],ids);expired.update(Vector3(-1,0,0),true,.1);expired.update(Vector3.ZERO,true,.1);expired.update(Vector3(1.5,0,0),true,5)
 check.call(expired.update(Vector3(3,0,0),false,.2,callback).is_empty()and calls.count==0,"expired gap never invokes native finish authority")
 var rejected:=Tracker.new();rejected.configure([source],ids);rejected.update(Vector3(-1,0,0),true,.1);rejected.update(Vector3.ZERO,true,.1)
 var no:Callable=func(_d:Dictionary,_a:Vector3,_b:Vector3,_frame:int)->bool:return false
 check.call(rejected.update(Vector3(3,0,0),false,.2,no).is_empty(),"native authority refusal has no generic grounded fallback")
 var ordered:=Tracker.new();ordered.configure([source],ids);ordered.update(Vector3(-1,0,0),true,.1);ordered.update(Vector3.ZERO,true,.1)
 var awards:Array=ordered.update(Vector3(3,0,0),false,.2,callback)
 check.call(awards.size()==1 and calls.count==1,"structural callback gate runs only after armed real-air ordered end/window checks; fixture callback is not native proof")
 check.call(ordered.update(Vector3(3,0,0),false,.1,callback).is_empty()and calls.count==1,"same finish cannot award or invoke its provider twice")
 var reversed:=Tracker.new();reversed.configure([source],ids);reversed.update(Vector3(-1,0,0),true,.1);reversed.update(Vector3.ZERO,true,.1);reversed.update(Vector3(-1,0,0),true,.1)
 check.call(reversed.update(Vector3(3,0,0),false,.2,callback).is_empty()and calls.count==1,"reversed armed attempt remains invalid with native policy")
 var reset:=Tracker.new();reset.configure([source],ids);reset.update(Vector3(-1,0,0),true,.1);reset.update(Vector3.ZERO,true,.1);reset.reset()
 check.call(reset.update(Vector3(3,0,0),false,.2,callback).is_empty()and calls.count==1,"reset removes armed native finish progress")
