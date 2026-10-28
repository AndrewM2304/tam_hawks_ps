extends "res://game/player/skater.gd"
func _witness_region()->bool:
 return global_position.x> -141.5 and global_position.x< -140.3 and global_position.z> -126.3 and global_position.z< -125.2
func _native_board_floor()->Dictionary:
 var result:Dictionary=super._native_board_floor()
 if _witness_region():print("SHOULDER_FLOOR at=",global_position," result=",result," floor=",is_on_floor()," native=",_native_floor_valid," air=",airborne," manual=",manual_active," board=",_board_visual.global_transform," normal=",_native_floor_normal()," rejection=",_grind_clearance.last_rejection," obstruction=",_grind_clearance.last_obstruction)
 return result
func _native_planar_rim_fit(point:Vector3,axis:Vector3,frame:Basis,bowl:Node3D=null)->Dictionary:
 var result:Dictionary=super._native_planar_rim_fit(point,axis,frame,bowl)
 if _witness_region():print("SHOULDER_PLANAR at=",global_position," point=",point," axis=",axis," frame=",frame," bowl=",bowl," result=",result)
 return result
func _native_footprint_board_fit(point:Vector3,axis:Vector3,frame:Basis,bowl:Node3D)->Dictionary:
 var result:Dictionary=super._native_footprint_board_fit(point,axis,frame,bowl)
 if _witness_region():print("SHOULDER_FOOTPRINT at=",global_position," point=",point," axis=",axis," result=",result)
 return result
func _native_rim_refinement_lift(pose:Transform3D,minimum:float=0.0,maximum:float=PLANAR_RIM_MAX_LIFT)->float:
 var result:float=super._native_rim_refinement_lift(pose,minimum,maximum)
 if _witness_region():print("SHOULDER_REFINE at=",global_position," pose=",pose," minimum=",minimum," maximum=",maximum," result=",result)
 return result
func _place_native_support_wheels(visual_yaw:float)->void:
 var before:=_visual.global_transform
 super._place_native_support_wheels(visual_yaw)
 if _witness_region():print("SHOULDER_NATIVE_POST at=",global_position," before=",before," after=",_visual.global_transform," board=",_board_visual.global_transform)
func _place_obstacle_wheels(delta:float)->void:
 var before:=_visual.global_transform
 super._place_obstacle_wheels(delta)
 if _witness_region():print("SHOULDER_OBSTACLE_POST at=",global_position," before=",before," after=",_visual.global_transform," board=",_board_visual.global_transform)
func _native_model_hits_support(frame:Transform3D,support:Dictionary)->bool:
 var result:bool=super._native_model_hits_support(frame,support)
 if _witness_region():print("SHOULDER_CURRENT_SUPPORT at=",global_position," support=",support," model_hits_same=",result," frame=",frame)
 return result
