extends SceneTree
## Isolated native encoding control: built-in cylinder frames, before/after
## upload through the same ArrayMesh path as SurfaceTool.commit(). No world.
func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	for spec: Array in [["old_pedestal",10,1.0,.65,2.0],
			["profile_pedestal",18,1.0,.65,2.0],
			["profile_bowl_outer",18,.65,1.65,.5],
			["profile_finial",12,.28,.12,.74]]:
		var cylinder := CylinderMesh.new()
		cylinder.radial_segments = spec[1]
		cylinder.rings = 3
		cylinder.bottom_radius = spec[2]
		cylinder.top_radius = spec[3]
		cylinder.height = spec[4]
		var source := cylinder.surface_get_arrays(0)
		# PrimitiveMesh exposes source arrays, but not ArrayMesh's native format.
		_report(spec[0]+"_builtin",source,-1)
		var encoded := ArrayMesh.new()
		encoded.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,source)
		_report(spec[0]+"_arraymesh",encoded.surface_get_arrays(0),encoded.surface_get_format(0))
	print("ORNAMENT_PACKING_CONTROL complete; diagnostic only")
	quit()

func _report(label: String, a: Array, format: int) -> void:
	var p: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var t: PackedFloat32Array = a[Mesh.ARRAY_TANGENT]
	var uv: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var ix: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var normal_error := 0.0
	var tangent_error := 0.0
	var dot_error := 0.0
	var angular_error := 0.0
	var handedness_error := 0.0
	var winding_failures := 0
	var degenerate := 0
	var nonfinite := 0
	for i: int in p.size():
		var tangent := Vector3(t[i*4],t[i*4+1],t[i*4+2])
		normal_error = maxf(normal_error,absf(n[i].length()-1.0))
		tangent_error = maxf(tangent_error,absf(tangent.length()-1.0))
		dot_error = maxf(dot_error,absf(tangent.dot(n[i])))
		angular_error = maxf(angular_error,rad_to_deg(asin(clampf(absf(tangent.normalized().dot(n[i].normalized())),0.0,1.0))))
		handedness_error = maxf(handedness_error,absf(absf(t[i*4+3])-1.0))
		nonfinite += int(not p[i].is_finite() or not n[i].is_finite() or not tangent.is_finite() or not uv[i].is_finite())
	for face: int in range(0,ix.size(),3):
		var cross: Vector3 = (p[ix[face+1]]-p[ix[face]]).cross(p[ix[face+2]]-p[ix[face]])
		winding_failures += int(cross.dot(n[ix[face]]+n[ix[face+1]]+n[ix[face+2]])>=0)
		degenerate += int(cross.length_squared()<=.0000000001)
	print("ORNAMENT_PACKING_CONTROL ",JSON.stringify({"name":label,"vertices":p.size(),"triangles":ix.size()/3,"format":format,"normal_length_error":normal_error,"tangent_length_error":tangent_error,"orthogonality_error":dot_error,"orthogonality_error_degrees":angular_error,"handedness_error":handedness_error,"winding_failures":winding_failures,"degenerate":degenerate,"nonfinite":nonfinite}))
