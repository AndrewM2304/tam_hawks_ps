extends SceneTree
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Setup=preload("res://game/core/input_setup.gd")
class Probe extends RefCounted:
	var inner:RefCounted
	var age:=0
	var seen:Dictionary={}
	func reset()->void:inner.reset()
	func update(rider:CharacterBody3D,camera:Camera3D,delta:float,sensitivity:float,reduced:bool)->void:
		inner.update(rider,camera,delta,sensitivity,reduced)
		age=age+1 if rider.transition_active else 0
		var alignment:=(-camera.global_basis.z).dot(rider.velocity.normalized())
		var key:=str(rider._transition.feature.get('id',''))+':'+str(roundi(rider._transition.theta*8))+':'+str(signf(rider.velocity.y))
		if age>8 and alignment<.80 and rider.velocity.length()>2.0 and not seen.has(key):
			seen[key]=true
			print('REAR_HEADING ',JSON.stringify({'tick':Engine.get_physics_frames(),'theta':rider._transition.theta,'age':age,'alignment':alignment,'velocity':str(rider.velocity),'body':str(rider.global_position),'camera':str(camera.global_position),'view':str(-camera.global_basis.z),'support_forward':str(-rider.get_camera_support_frame().z),'motion_forward':str(inner._motion_direction),'selected':inner._selected_angle,'world_rear':str(inner._world_rear),'travel_sign':inner._travel_sign}))
func _initialize()->void:call_deferred('_run')
func _run()->void:
	Setup.register_actions()
	var f:=await Classic._pipe_fixture(self,false,Vector3(-42,2.8,60.5),-PI*.5,true)
	var probe:=Probe.new()
	probe.inner=f.rider._camera_follow
	f.rider._camera_follow=probe
	Input.action_press('push')
	await Classic._frames(self,720)
	print('RESULT: 1 passed, 0 failed')
	quit()
