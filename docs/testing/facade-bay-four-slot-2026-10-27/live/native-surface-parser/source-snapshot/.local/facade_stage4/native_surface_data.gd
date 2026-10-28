extends SceneTree
func _initialize() -> void:
	var rows: Array=[]
	for folder: String in ["glasgow_bay","glasgow_bay_reduced_four_slot"]:
		for lod: String in ["near","mid","far"]:
			var packed: PackedScene=load("res://game/art/assets/"+folder+"/glasgow_bay_"+lod+".glb")
			var model: Node=packed.instantiate()
			var mesh: Mesh=model.find_children("*","MeshInstance3D",true,false)[0].mesh
			var surfaces: Array=[]
			var totals: Dictionary={"vertex_data":0,"attribute_data":0,"skin_data":0,"index_data":0}
			for slot: int in mesh.get_surface_count():
				var data: Dictionary=RenderingServer.mesh_get_surface(mesh.get_rid(),slot)
				var sizes: Dictionary={}
				for field: String in totals:
					var value: Variant=data.get(field)
					sizes[field]=value.size() if value is PackedByteArray else -1
					if sizes[field]>=0:totals[field]+=sizes[field]
				surfaces.append({"slot":slot,"format":mesh.surface_get_format(slot),"native_dictionary_keys":data.keys(),"vertex_count":data.get("vertex_count",-1),"index_count":data.get("index_count",-1),"data_bytes":sizes})
			var threshold_y: Array=[]
			var faces: PackedVector3Array=mesh.get_faces()
			var threshold_area: float=0
			for i: int in range(0,faces.size(),3):
				var found: bool=true
				var strict: bool=true
				for j: int in range(3):
					var at: Vector3=faces[i+j]
					found=found and absf(at.y-.53)<.01 and at.x>1.399 and at.x<2.601 and at.z>-.226 and at.z<.276
					strict=strict and absf(at.y-.53)<.0001
				if found:
					threshold_y.append([faces[i].y,faces[i+1].y,faces[i+2].y])
					if strict:threshold_area+=(faces[i+1]-faces[i]).cross(faces[i+2]-faces[i]).length()*.5
			rows.append({"asset":folder,"lod":lod,"triangles":faces.size()/3,"native_byte_array_totals":totals,"surfaces":surfaces,"native_threshold_y":threshold_y,"strict_threshold_area":threshold_area})
			model.free()
	var result: Dictionary={"display":DisplayServer.get_name(),"compress_attributes_flag":Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES,"rows":rows,"interpretation":"RenderingServer native surface byte arrays, not GLB file sizes or a VRAM-residency measurement"}
	var args: PackedStringArray=OS.get_cmdline_user_args()
	if args.size()>0:
		var file: FileAccess=FileAccess.open(args[0],FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"\t")+"\n")
	print(JSON.stringify(result))
	quit()
