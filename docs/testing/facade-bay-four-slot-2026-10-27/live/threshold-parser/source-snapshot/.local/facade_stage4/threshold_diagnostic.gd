extends SceneTree
func _initialize() -> void:
	for folder: String in ["glasgow_bay","glasgow_bay_reduced_four_slot"]:
		var packed: PackedScene=load("res://game/art/assets/"+folder+"/glasgow_bay_near.glb")
		var model: Node=packed.instantiate()
		var mesh: Mesh=model.find_children("*","MeshInstance3D",true,false)[0].mesh
		var faces: PackedVector3Array=mesh.get_faces()
		var rows: Array=[]
		var strict_area: float=0
		for i: int in range(0,faces.size(),3):
			var found: bool=true
			var strict: bool=true
			for j: int in range(3):
				var at: Vector3=faces[i+j]
				found=found and absf(at.y-.53)<.01 and at.x>1.399 and at.x<2.601 and at.z>-.226 and at.z<.276
				strict=strict and absf(at.y-.53)<.0001
			if found:
				var area: float=(faces[i+1]-faces[i]).cross(faces[i+2]-faces[i]).length()*.5
				rows.append({"vertices":[faces[i],faces[i+1],faces[i+2]],"area":area,"strict_y":strict})
				if strict:strict_area+=area
		print(JSON.stringify({"asset":folder,"aabb":mesh.get_aabb(),"format":mesh.surface_get_format(0),"strict_threshold_area":strict_area,"nearby_threshold_triangles":rows}))
		model.free()
	quit()
