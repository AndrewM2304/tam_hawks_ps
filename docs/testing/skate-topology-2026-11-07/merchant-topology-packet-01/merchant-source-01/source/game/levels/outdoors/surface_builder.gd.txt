extends RefCounted
## Original shared mesh/collision construction for continuous outdoor surfaces.
const EDGE_OWNERSHIP_EPSILON := 0.00005 # 50 micrometres; exterior-ray precision only.

## The same two triangles used by terrain(), rather than the unsampled height
## function between mesh vertices. Queries/fence feet must agree with collision.
static func grid_height(bounds: Rect2, spacing: float, height_at: Callable, x: float, z: float) -> float:
	var nx := ceili(bounds.size.x/spacing)
	var nz := ceili(bounds.size.y/spacing)
	var dx := bounds.size.x/nx
	var dz := bounds.size.y/nz
	var gx := clampf((x-bounds.position.x)/dx,0,nx)
	var gz := clampf((z-bounds.position.y)/dz,0,nz)
	var ix := mini(floori(gx),nx-1)
	var iz := mini(floori(gz),nz-1)
	var u := gx-ix
	var v := gz-iz
	var left := bounds.position.x+ix*dx
	var north := bounds.position.y+iz*dz
	var a := float(height_at.call(left,north))
	var b := float(height_at.call(left+dx,north))
	var c := float(height_at.call(left,north+dz))
	var d := float(height_at.call(left+dx,north+dz))
	return a+u*(b-a)+v*(c-a) if u+v<=1.0 else d+(1-u)*(c-d)+(1-v)*(b-d)


static func terrain(parent: Node3D, id: String, bounds: Rect2, spacing: float, height_at: Callable, material: Material,
		cutouts: Array[Rect2] = []) -> StaticBody3D:
	var nx := ceili(bounds.size.x / spacing)
	var nz := ceili(bounds.size.y / spacing)
	var dx := bounds.size.x / nx
	var dz := bounds.size.y / nz
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for z in range(nz + 1):
		for x in range(nx + 1):
			var px := bounds.position.x + x * dx
			var pz := bounds.position.y + z * dz
			vertices.append(Vector3(px, float(height_at.call(px, pz)), pz))
			uvs.append(Vector2(px, pz) * 0.2)
	for z in range(nz + 1):
		for x in range(nx + 1):
			var left := vertices[z * (nx + 1) + maxi(0, x - 1)].y
			var right := vertices[z * (nx + 1) + mini(nx, x + 1)].y
			var north := vertices[maxi(0, z - 1) * (nx + 1) + x].y
			var south := vertices[mini(nz, z + 1) * (nx + 1) + x].y
			normals.append(Vector3((left - right) / dx, 2.0, (north - south) / dz).normalized())
			if x < nx and z < nz:
				var cell_center := Vector2(bounds.position.x+(x+0.5)*dx,bounds.position.y+(z+0.5)*dz)
				var excavated := false
				for cutout: Rect2 in cutouts:
					if cutout.has_point(cell_center):
						excavated = true
						break
				if excavated: continue
				var a := z * (nx + 1) + x
				indices.append_array(PackedInt32Array([a, a + 1, a + nx + 1, a + 1, a + nx + 2, a + nx + 1]))
	var result := _body(parent, id, vertices, normals, uvs, indices, material, "stone")
	result.set_meta("terrain_cutouts",cutouts.duplicate())
	return result


## visual_points may end a road at a shared paving seam. Collision keeps the
## original authored strip; never stack two different visible surfaces in-plane.
static func strip(parent: Node3D, id: String, points: PackedVector3Array, width: float, material: Material, audio: String = "stone", visual_points: PackedVector3Array = PackedVector3Array()) -> StaticBody3D:
	var arrays := _strip_arrays(points, width)
	var visual_arrays := _strip_arrays(visual_points, width) if visual_points.size() >= 2 else []
	var body := _body(parent, id, arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_NORMAL], arrays[Mesh.ARRAY_TEX_UV], arrays[Mesh.ARRAY_INDEX], material, audio, visual_arrays)
	# The full collision strip stays authoritative when only the displayed road
	# is trimmed at a paving seam. Cache its exact paired vertices once.
	body.set_meta("support_vertices",arrays[Mesh.ARRAY_VERTEX])
	body.set_meta("strip_vertices",arrays[Mesh.ARRAY_VERTEX])
	body.set_meta("strip_indices",arrays[Mesh.ARRAY_INDEX])
	return body


## Trim only displayed road triangles out of a shared level quay. The curved
## approach retains its exact original strip collider and support vertices.
## Startup-only native polygon subtraction avoids coplanar asphalt/paving.
static func trim_visual_rect(body: StaticBody3D, bounds: Rect2) -> void:
	var clip := PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),
		bounds.end,Vector2(bounds.position.x,bounds.end.y)])
	trim_visual_polygon(body,clip)


static func trim_visual_polygon(body: StaticBody3D, clip: PackedVector2Array) -> void:
	for child: Node in body.get_children():
		if not child is MeshInstance3D: continue
		var visual := child as MeshInstance3D
		var faces := visual.mesh.get_faces()
		var output := SurfaceTool.new()
		output.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index: int in range(0,faces.size(),3):
			var a := faces[index]
			var b := faces[index+1]
			var c := faces[index+2]
			var normal := (b-a).cross(c-a).normalized()
			if normal.y<0: normal=-normal
			var triangle := PackedVector2Array([Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z)])
			for polygon: PackedVector2Array in Geometry2D.clip_polygons(triangle,clip):
				var indices := Geometry2D.triangulate_polygon(polygon)
				for at: int in range(0,indices.size(),3):
					var corners := PackedVector3Array()
					for corner: int in 3:
						var xz := polygon[indices[at+corner]]
						var y := a.y-(normal.x*(xz.x-a.x)+normal.z*(xz.y-a.z))/normal.y
						corners.append(Vector3(xz.x,y,xz.y))
					if (corners[1]-corners[0]).cross(corners[2]-corners[0]).y>0:
						var swap := corners[1]; corners[1]=corners[2]; corners[2]=swap
					for point: Vector3 in corners:
						output.set_normal(normal)
						output.set_uv(Vector2(point.x,point.z)*0.2)
						output.add_vertex(point)
		output.index()
		output.generate_tangents()
		visual.mesh=output.commit()


## Startup-only excavation of flat, identity-transform terrain. The convex cut
## crosses the small source triangles; it must not fit wholly inside one face.
## Display and collision are independent so earlier display-only trims survive.
static func excavate_flat(body: StaticBody3D, mouth: PackedVector2Array, deck: PackedVector2Array) -> void:
	assert(body.transform.is_equal_approx(Transform3D.IDENTITY))
	for child: Node in body.get_children():
		if child is CollisionShape3D and child.shape is ConcavePolygonShape3D:
			child.shape.set_faces(_subtract_flat_faces(child.shape.get_faces(),mouth))
		elif child is MeshInstance3D:
			var before: int = child.mesh.get_faces().size()/3
			var output := SurfaceTool.new()
			output.begin(Mesh.PRIMITIVE_TRIANGLES)
			for point: Vector3 in _subtract_flat_faces(child.mesh.get_faces(),deck):
				output.set_normal(Vector3.UP)
				output.set_uv(Vector2(point.x,point.z)*0.2)
				output.add_vertex(point)
			output.generate_tangents()
			child.mesh = output.commit()
			body.set_meta("excavation_added_visual_triangles",child.mesh.get_faces().size()/3-before)


static func _subtract_flat_faces(faces: PackedVector3Array, clip: PackedVector2Array) -> PackedVector3Array:
	var result := PackedVector3Array()
	for index in range(0,faces.size(),3):
		var a := faces[index]
		var b := faces[index+1]
		var c := faces[index+2]
		assert(absf(a.y-b.y)<0.00001 and absf(a.y-c.y)<0.00001)
		var triangle := PackedVector2Array([Vector2(a.x,a.z),Vector2(b.x,b.z),Vector2(c.x,c.z)])
		for polygon: PackedVector2Array in Geometry2D.clip_polygons(triangle,clip):
			var indices := Geometry2D.triangulate_polygon(polygon)
			for at in range(0,indices.size(),3):
				var corners := PackedVector3Array()
				for corner in 3:
					var p := polygon[indices[at+corner]]
					corners.append(Vector3(p.x,a.y,p.y))
				if (corners[1]-corners[0]).cross(corners[2]-corners[0]).y>0:
					var swap := corners[1]; corners[1]=corners[2]; corners[2]=swap
				result.append_array(corners)
	return result


## Exact footprint and triangle-plane height of the paired ribbon vertices.
## A nearest-centreline radius invents support beyond inside corners and gives
## wrong side heights on a graded bend, even when the mesh itself is sound.
static func strip_height(vertices: PackedVector3Array,at: Vector2) -> float:
	var highest := NAN
	for index: int in range(0,vertices.size()-2,2):
		var a:=vertices[index]
		var b:=vertices[index+1]
		var c:=vertices[index+2]
		var d:=vertices[index+3]
		if at.x<minf(minf(a.x,b.x),minf(c.x,d.x)) or at.x>maxf(maxf(a.x,b.x),maxf(c.x,d.x)) \
			or at.y<minf(minf(a.z,b.z),minf(c.z,d.z)) or at.y>maxf(maxf(a.z,b.z),maxf(c.z,d.z)): continue
		for triangle_index: int in range(2):
			var triangle: Array=[a,b,c] if triangle_index==0 else [b,d,c]
			var first: Vector3=triangle[0]
			var second: Vector3=triangle[1]
			var third: Vector3=triangle[2]
			var ab:=Vector2(second.x-first.x,second.z-first.z)
			var ac:=Vector2(third.x-first.x,third.z-first.z)
			var relative:=at-Vector2(first.x,first.z)
			var denominator:=ab.cross(ac)
			if absf(denominator)<0.0000001: continue
			var second_weight:=relative.cross(ac)/denominator
			var third_weight:=ab.cross(relative)/denominator
			var first_weight:=1.0-second_weight-third_weight
			if minf(first_weight,minf(second_weight,third_weight))< -0.000001: continue
			# Shared quad diagonals/cross-sections are inclusive. The engine's
			# generic triangle test excludes a shared diagonal and invented a NAN
			# hole at the centre of an otherwise solid approach. Exterior edges
			# instead belong to the adjoining terrain, like core stair seams.
			var area:=absf(denominator)
			if triangle_index==0:
				if second_weight*area/ac.length()<=EDGE_OWNERSHIP_EPSILON or (index==0 and third_weight*area/ab.length()<=EDGE_OWNERSHIP_EPSILON): continue
			else:
				if third_weight*area/ab.length()<=EDGE_OWNERSHIP_EPSILON or (index==vertices.size()-4 and first_weight*area/Vector2(third.x-second.x,third.z-second.z).length()<=EDGE_OWNERSHIP_EPSILON): continue
			var height:=first.y*first_weight+second.y*second_weight+third.y*third_weight
			if is_nan(highest) or height>highest: highest=height
	return highest


static func _strip_arrays(points: PackedVector3Array, width: float) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var distance := 0.0
	for i in points.size():
		var direction := points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]
		var side := Vector3(direction.z, 0.0, -direction.x).normalized()
		var normal := side.cross(direction).normalized()
		if normal.y < 0.0: normal = -normal
		if i > 0: distance += points[i].distance_to(points[i - 1])
		vertices.append(points[i] - side * width * 0.5)
		vertices.append(points[i] + side * width * 0.5)
		normals.append_array(PackedVector3Array([normal, normal]))
		uvs.append_array(PackedVector2Array([Vector2(0, distance * 0.2), Vector2(width * 0.2, distance * 0.2)]))
		if i < points.size() - 1:
			var a := i * 2
			indices.append_array(PackedInt32Array([a, a + 1, a + 2, a + 1, a + 3, a + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


static func _body(parent: Node3D, id: String, vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array, material: Material, audio: String, visual_arrays: Array = []) -> StaticBody3D:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var body := StaticBody3D.new()
	body.name = id
	body.set_meta("geometry_id", id)
	body.set_meta("art_label", id)
	body.collision_layer = 1
	body.collision_mask = 0
	body.set_meta("surface_audio", audio)
	body.add_to_group("outdoor_surfaces")
	parent.add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	if not visual_arrays.is_empty():
		var visible_mesh := ArrayMesh.new()
		visible_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, visual_arrays)
		visual.mesh = visible_mesh
	visual.material_override = material
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape()
	shape.backface_collision = true
	collision.shape = shape
	body.add_child(collision)
	return body


static func smooth_points(knots: PackedVector3Array, spacing: float = 2.0) -> PackedVector3Array:
	var curve := Curve3D.new()
	curve.bake_interval = 0.4
	for i in knots.size():
		var tangent := (knots[mini(i + 1, knots.size() - 1)] - knots[maxi(i - 1, 0)]) * 0.16
		# A flat landing/port must stay flat: unconstrained cardinal Y tangents
		# overshoot below it and allow neighbouring paving to intersect the path.
		if i > 0 and i < knots.size() - 1:
			var before := knots[i].y - knots[i - 1].y
			var after := knots[i + 1].y - knots[i].y
			if before * after <= 0.0: tangent.y = 0.0
		curve.add_point(knots[i], -tangent if i > 0 else Vector3.ZERO, tangent if i < knots.size() - 1 else Vector3.ZERO)
	var samples := PackedVector3Array()
	var steps := maxi(1, ceili(curve.get_baked_length() / spacing))
	for i in range(steps + 1): samples.append(curve.sample_baked(curve.get_baked_length() * float(i) / steps, true))
	samples[0] = knots[0]
	samples[samples.size() - 1] = knots[knots.size() - 1]
	return samples


static func nearest_segment(points: PackedVector3Array, at: Vector2) -> Dictionary:
	var best := INF
	var result := {"distance": INF, "height": NAN}
	for i in range(points.size() - 1):
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[i + 1].x, points[i + 1].z)
		var delta := b - a
		var raw_weight := (at - a).dot(delta) / maxf(0.0001, delta.length_squared())
		var weight := clampf(raw_weight, 0.0, 1.0)
		var distance := at.distance_squared_to(a + delta * weight)
		if distance < best:
			best = distance
			var closest := a+delta*weight
			var endpoint_distance := minf(closest.distance_to(Vector2(points[0].x,points[0].z)),
				closest.distance_to(Vector2(points[-1].x,points[-1].z)))
			result = {"distance": sqrt(distance), "height": lerpf(points[i].y, points[i + 1].y, weight),
				"endpoint_distance":endpoint_distance,
				"within": not ((i == 0 and raw_weight < 0.0) or (i == points.size() - 2 and raw_weight > 1.0))}
	return result


## Close a raised ribbon down to its actual resident ground. Reuse its body,
## native shape and top surface; the masonry skirt is one startup-only surface.
static func solidify_strip(body: StaticBody3D, ground: Callable, masonry: Material,
		covered: Array[Rect2] = []) -> void:
	var vertices:PackedVector3Array=body.get_meta("support_vertices")
	var perimeter:=PackedVector3Array([vertices[0]])
	for i in range(1,vertices.size(),2):perimeter.append(vertices[i])
	for i in range(vertices.size()-2,-1,-2):perimeter.append(vertices[i])
	solidify_perimeter(body,perimeter,ground,masonry,covered)


## The closed perimeter is independent of the terrain's triangulation. Face
## winding follows its signed area, so skirts render from the accessible
## exterior instead of only from inside the raised road.
static func solidify_perimeter(body: StaticBody3D, perimeter: PackedVector3Array,
		ground: Callable, masonry: Material, covered: Array[Rect2] = []) -> void:
	assert(perimeter.size() >= 4 and perimeter[0].is_equal_approx(perimeter[-1]))
	var signed_area := 0.0
	for i in range(perimeter.size()-1):
		signed_area += perimeter[i].x*perimeter[i+1].z-perimeter[i+1].x*perimeter[i].z
	assert(absf(signed_area)>0.0001)
	var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tool.set_material(masonry)
	var triangles := 0
	var side_faces := PackedVector3Array()
	for i in range(perimeter.size()-1):
		var start:=perimeter[i];var finish:=perimeter[i+1]
		var intervals: Array[Vector2] = [Vector2(0,1)]
		# Cut shared terrace edges exactly before subdivision. Two masonry skins
		# on the same rim would recreate the reported coplanar wall shimmer.
		for bounds: Rect2 in covered:
			var pieces: Array[Vector2] = []
			for interval: Vector2 in intervals:
				var first := start.lerp(finish,interval.x)
				var last := start.lerp(finish,interval.y)
				var line := PackedVector2Array([Vector2(first.x,first.z),Vector2(last.x,last.z)])
				var polygon := PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
				for piece: PackedVector2Array in Geometry2D.clip_polyline_with_polygon(line,polygon):
					var delta := Vector2(finish.x-start.x,finish.z-start.z)
					pieces.append(Vector2((piece[0]-Vector2(start.x,start.z)).dot(delta)/delta.length_squared(),
						(piece[-1]-Vector2(start.x,start.z)).dot(delta)/delta.length_squared()))
			intervals=pieces
		for interval: Vector2 in intervals:
			var count:=maxi(1,ceili(start.distance_to(finish)*absf(interval.y-interval.x)/.5))
			for j in count:
				var a:=start.lerp(finish,lerpf(interval.x,interval.y,float(j)/count))
				var b:=start.lerp(finish,lerpf(interval.x,interval.y,float(j+1)/count))
				var base_a := float(ground.call(a.x,a.z))
				var base_b := float(ground.call(b.x,b.z))
				assert(is_finite(base_a) and is_finite(base_b),"Raised paving needs resident ground: "+str(body.name))
				var c:=Vector3(a.x,minf(a.y-.04,base_a-.08),a.z)
				var d:=Vector3(b.x,minf(b.y-.04,base_b-.08),b.z)
				var faces := PackedVector3Array([a,b,c,b,d,c] if signed_area<0 else [a,c,b,b,c,d])
				var normal:=-(faces[1]-faces[0]).cross(faces[2]-faces[0]).normalized()
				for at:Vector3 in faces:
					tool.set_normal(normal);tool.set_uv(Vector2(at.x+at.z,at.y)*.5);tool.add_vertex(at)
				side_faces.append_array(faces)
				triangles += 2
	var mesh:MeshInstance3D=body.get_child(0)
	var original:ArrayMesh=mesh.mesh
	original.surface_set_material(0,mesh.material_override)
	mesh.material_override=null
	mesh.mesh=tool.commit(original)
	# Display-only seam clipping must not remove the original supported top.
	# Append precisely the new masonry faces to the resident native shape.
	var shape: ConcavePolygonShape3D=body.get_child(1).shape
	var collision_faces:=shape.get_faces()
	collision_faces.append_array(side_faces)
	shape.set_faces(collision_faces)
	body.set_meta("retaining_perimeter",perimeter)
	body.set_meta("retaining_triangles",triangles)
