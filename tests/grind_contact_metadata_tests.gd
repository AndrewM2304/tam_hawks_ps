extends RefCounted
## Support datums are geometry evidence, separate from capture/travel eligibility.
## Original coordinates only; these checks do not establish physical trick feel.

const Line = preload("res://game/tricks/grind_line.gd")
const Edges = preload("res://game/levels/skate_edges.gd")
const Skater = preload("res://game/player/skater.gd")


static func run(check: Callable) -> void:
	var flat := Line.new("flat",PackedVector3Array([Vector3(2,3,8),Vector3(2,3,-8)]))
	var points_before := flat.points.duplicate()
	var length_before: float = flat.length
	check.call(not flat.contact_verified and flat.contact_source.is_empty()
		and flat.contact_at(4).is_equal_approx(flat.point_at(4)),
		"grind contact: legacy guides remain explicitly unverified without an invented offset")
	check.call(flat.configure_contact(0.0,0.0,"  original box top  ") == flat
		and flat.contact_verified and flat.contact_source == "original box top"
		and flat.contact_at(4).is_equal_approx(Vector3(2,3,4)),
		"grind contact: inspected top datum configures chainably with a retained source")
	check.call(flat.points == points_before and flat.length == length_before
		and flat.dir_at(4).is_equal_approx(Vector3.FORWARD),
		"grind contact: metadata cannot rewrite authored travel points, length or tangent")
	check.call(flat.contact_up(4).is_equal_approx(Vector3.UP)
		and flat.contact_at(-2).is_equal_approx(flat.points[0])
		and flat.contact_at(flat.length+2).is_equal_approx(flat.points[-1]),
		"grind contact: flat normal and existing open-guide distance clamping remain explicit")

	var frame := Transform3D(Basis(Vector3.UP,0.61),Vector3(37,5,-19))
	var local := PackedVector3Array([Vector3(0,2,4),Vector3(0,2,-8)])
	var moved := Line.from_local_points("moved",local,frame).configure_contact(0.0,0.12,"original translated beam")
	check.call(moved.contact_verified and moved.contact_at(3).distance_to(frame*Vector3(0,2,1)+Vector3.UP*0.12)<0.00001
		and moved.points[0].is_equal_approx(frame*local[0]),
		"grind contact: translated unit-yaw beam keeps world-space support and original guide coordinates")

	var grade := Line.new("grade",PackedVector3Array([Vector3(3,2,4),Vector3(3,5,-8)]))
	var tangent := Vector3(0,3,-12).normalized()
	var expected_up := Vector3.UP.slide(tangent).normalized()
	grade.configure_contact(0.0,0.20,"original graded square beam")
	var offset: Vector3 = grade.contact_at(4)-grade.point_at(4)
	check.call(grade.contact_verified and grade.contact_up(4).distance_to(expected_up)<0.00001
		and absf(grade.contact_up(4).dot(tangent))<0.00001
		and absf(grade.contact_up(4).length()-1.0)<0.00001,
		"grind contact: grade support normal is unit projected world-up perpendicular to actual tangent")
	check.call(offset.distance_to(expected_up*0.20)<0.00001
		and absf(offset.length()-0.20)<0.00001 and offset.distance_to(Vector3.UP*0.20)>0.01,
		"grind contact: centre-authored graded beam uses normal radius rather than a vertical-only height")
	var reversed := Line.new("reverse",PackedVector3Array([grade.points[-1],grade.points[0]]))
	reversed.configure_contact(0.0,0.20,"original reversed beam")
	check.call(reversed.contact_up(grade.length-4).distance_to(expected_up)<0.00001
		and reversed.contact_at(grade.length-4).distance_to(grade.contact_at(4))<0.0001,
		"grind contact: support side does not invert with authored or ridden travel direction")
	grade.configure_contact(-0.07,0.07,"original lowered cylinder envelope")
	check.call(grade.contact_at(4).distance_to(grade.point_at(4)-Vector3.UP*0.07+expected_up*0.07)<0.00001,
		"grind contact: lowered graded cylinder combines its world-vertical lowering and radial support")
	flat.configure_contact(-0.07,0.07,"original lowered flat cylinder envelope")
	check.call(flat.contact_at(4).distance_to(flat.point_at(4))<0.00001,
		"grind contact: lowered flat cylinder guide already describes its top, not its centre")
	flat.configure_contact(-Edges.SKIN,0.0,"original semantic top without skin")
	check.call(flat.contact_at(4).distance_to(flat.point_at(4)-Vector3.UP*Edges.SKIN)<0.00001,
		"grind contact: semantic admission skin is removed in world up without changing its guide")

	var loop := Line.new("loop",PackedVector3Array([Vector3(0,2,0),Vector3(0,2,-4),
		Vector3(4,2,-4),Vector3(4,2,0),Vector3(0,2,0)]))
	loop.configure_contact(0.0,0.1,"original closed beam")
	check.call(loop.contact_verified and loop.is_loop
		and loop.contact_at(0).distance_to(loop.contact_at(loop.length))<0.00001
		and loop.contact_up(0).is_equal_approx(Vector3.UP),
		"grind contact: closed-guide seam retains matching finite support at existing wrapped endpoints")
	_normal_joint_refusals(check)

	for bad: Array in [[NAN,0.0,"bad vertical"],[0.0,INF,"bad normal"],
		[0.5001,0.0,"too far vertical"],[0.0,-0.5001,"too far normal"],[0.0,0.0," \t "]]:
		flat.configure_contact(0.0,0.1,"previously inspected")
		flat.configure_contact(float(bad[0]),float(bad[1]),str(bad[2]))
		check.call(not flat.contact_verified and flat.contact_source.is_empty()
			and flat.contact_vertical_offset==0.0 and flat.contact_normal_offset==0.0
			and flat.contact_at(4).is_equal_approx(flat.point_at(4)),
			"grind contact: malformed replacement clears stale authority and finite offsets "+str(bad))
	var empty := Line.new("empty",PackedVector3Array())
	empty.configure_contact(0.0,0.0,"not geometry")
	var vertical := Line.new("vertical",PackedVector3Array([Vector3.ZERO,Vector3.UP*5]))
	vertical.configure_contact(0.0,0.1,"undefined upward side")
	check.call(not empty.contact_verified and empty.contact_up(0)==Vector3.ZERO
		and empty.contact_at(0)==Vector3.ZERO and not vertical.contact_verified
		and vertical.contact_up(2)==Vector3.ZERO,
		"grind contact: missing and vertical geometry cannot acquire a manufactured support side")
	check.call(flat.contact_at(NAN)==Vector3.ZERO and flat.contact_up(INF)==Vector3.ZERO,
		"grind contact: nonfinite query distances cannot contaminate a physical transform")
	flat.configure_contact(0.0,0.1,"inspected before external corruption")
	flat.contact_normal_offset=NAN
	check.call(flat.contact_at(4).is_equal_approx(flat.point_at(4)),
		"grind contact: direct malformed metadata mutation cannot return a nonfinite contact position")

	var top_frame:=Transform3D(Basis(Vector3.UP,PI*0.5),Vector3(10,2,-5))
	var tops:=Edges.box_top(top_frame,Vector3(4,2,6))
	var expected:=PackedVector3Array([Vector3(7,3.04,-3),Vector3(7,3.04,-7),Vector3(13,3.04,-7),Vector3(13,3.04,-3)])
	var preserved:=tops.size()==expected.size()
	for index: int in expected.size():
		preserved=preserved and tops[index].distance_to(expected[index])<0.00001
	check.call(preserved,
		"grind contact: original semantic box guide preserves exact translated/yawed top corners plus world-up admission skin")


static func run_world(world: Node,check: Callable) -> void:
	var unit:=Transform3D(Basis(Vector3.UP,0.4),Vector3(7,3,-9))
	check.call(world._grind_contact_frame_supported(unit)
		and not world._grind_contact_frame_supported(Transform3D(Basis(Vector3.RIGHT,0.2),Vector3.ZERO)),
		"grind contact world: authored rail metadata accepts unit upright translation/yaw and refuses tilted author frames")
	for basis: Basis in [Basis.from_scale(Vector3(2,1,1)),Basis.from_scale(Vector3(-1,1,1)),
		Basis(Vector3.FORWARD,0.2),Basis(Vector3(1,0,0),Vector3(0.1,1,0),Vector3(0,0,1))]:
		check.call(not world._grind_contact_frame_supported(Transform3D(basis,Vector3.ZERO)),
			"grind contact world: unsupported scale, reflection, roll or shear retains unverified rail source "+str(basis))
	var lines: Array = world.get_grind_lines()
	for specification: Array in [
		["Grind_Rail_Exchange",0.0,0.0,"glasgow.box_bar_top"],
		["Grind_Ledge_MerchantClose",-0.07,0.07,"glasgow.lowered_cylinder_envelope"],
		["Grind_Coping_ExchangeFountain",-0.23,0.23,"glasgow.lowered_cylinder_envelope"],
		["clyde_quay_coping",0.0,0.22,"outdoors.square_beam_normal_top"],
		["kelvingrove_cutback_ledge",0.0,0.18,"outdoors.square_beam_normal_top"],
		["clyde_quarter_coping",0.0,0.0,"transition.cylinder_top"]]:
		var line: RefCounted = _find(lines,str(specification[0]))
		check.call(line!=null and line.contact_verified and line.contact_source==str(specification[3])
			and is_equal_approx(line.contact_vertical_offset,float(specification[1]))
			and is_equal_approx(line.contact_normal_offset,float(specification[2])),
			"grind contact world: inspected authored support source and offsets "+str(specification[0]))

	var rail: RefCounted = _find(lines,"Grind_Rail_Exchange")
	var bar: Node3D = world.get_node("Grind_Rail_Exchange/RailProp")
	var actual_top := Vector3.ZERO
	var found_shape := false
	for child: Node in bar.get_children():
		if child is CollisionShape3D and child.shape is BoxShape3D:
			actual_top=child.global_transform*Vector3(0,child.shape.size.y/2,0)
			found_shape=true
	check.call(rail!=null and found_shape
		and rail.contact_at(rail.length*0.5).distance_to(actual_top)<0.0001,
		"grind contact world: original flat rail contact matches the real visible bar collider top")

	var graded: RefCounted = _find(lines,"Grind_Ledge_MerchantClose")
	var author: Node3D = world.get_node("Grind_Ledge_MerchantClose")
	var rendered_top := Vector3.ZERO
	var first_length := 0.0
	var found_cylinder := false
	for child: Node in author.get_children():
		if child is MultiMeshInstance3D and child.multimesh.mesh is CylinderMesh:
			# Dummy rendering need not retain readable MultiMesh GPU transforms.
			# Compare the original constructor endpoints and actual mesh radius;
			# native captures separately certify the displayed instance placement.
			var points: PackedVector3Array=author.get_meta("grind_points")
			var first: Vector3=author.to_global(points[0])
			var second: Vector3=author.to_global(points[1])
			first_length=first.distance_to(second)
			var up:=Vector3.UP.slide((second-first).normalized()).normalized()
			var radius: float=child.multimesh.mesh.top_radius
			rendered_top=(first+second)*0.5-Vector3.UP*radius+up*radius
			found_cylinder=true
	check.call(graded!=null and found_cylinder
		and graded.contact_at(first_length*0.5).distance_to(rendered_top)<0.0001,
		"grind contact world: straight graded Merchant Close datum matches lowered endpoints and actual cylinder radius")
	# No scene/physics fixture is needed for the unverified-geometry branch: it
	# must retain the original generic classification before any board query.
	var rider := Skater.new()
	for id: String in ["Grind_Rail_GallerySteps","Grind_Rail_George","Grind_Rail_MarketSteps","clyde_bridge_rail"]:
		var line: RefCounted = _find(lines,id)
		var generic := false
		if line!=null and not line.contact_verified:
			generic=rider._grind_candidate_supported(line,line.length*0.5,1.0)
		var chosen: Dictionary={} if line==null else rider._grind_choices.get(line.get_instance_id(),{})
		check.call(line!=null and not line.contact_verified and line.contact_source.is_empty()
			and line.contact_at(line.length*0.5).is_equal_approx(line.point_at(line.length*0.5))
			and generic and chosen.get("id","")=="rail_grind",
			"grind contact world: changing-grade author keeps unchanged guide and actual generic player classification "+id)
	var semantic_count := 0
	var uncertain_slats := 0
	var semantic_valid := true
	for line: RefCounted in lines:
		if not String(line.id).begins_with(Edges.PREFIX): continue
		semantic_count+=1
		var distance: float=line.length*0.5
		var generic := false
		if not line.contact_verified:
			generic=rider._grind_candidate_supported(line,distance,1.0)
		var chosen: Dictionary=rider._grind_choices.get(line.get_instance_id(),{})
		semantic_valid=semantic_valid and not line.contact_verified and line.contact_source.is_empty() \
			and line.contact_vertical_offset==0.0 and line.contact_normal_offset==0.0 \
			and line.contact_at(distance).is_equal_approx(line.point_at(distance)) \
			and generic and chosen.get("id","")=="rail_grind"
		if String(line.id).begins_with(Edges.PREFIX+"StreetBenchSeat_") \
				or String(line.id).begins_with(Edges.PREFIX+"StreetBenchBack_"):
			uncertain_slats+=1
	check.call(semantic_count>0 and uncertain_slats>0 and semantic_valid,
		"grind contact world: every semantic source keeps original generic classification and unchanged guide until conforming solid-edge contact is supported")
	for specification: Array in [["Planter_",Vector3(-29,0.84,11.5)],
		["MarketCounter_",Vector3(109.5,1.24,2)],["StreetBenchSeat_",Vector3(29,0.585,27.26)],
		["BridgeRail_",Vector3(-28.85,3.8,81)]]:
		var gap:=INF
		for line: RefCounted in lines:
			if not String(line.id).begins_with(Edges.PREFIX+str(specification[0])): continue
			var closest: Dictionary=line.closest(specification[1])
			if not closest.is_empty(): gap=minf(gap,float(closest.gap))
		check.call(gap<0.30,
			"grind contact world: established real semantic route retains its original authored identity and top-guide location "+str(specification[0]))
	print("GRIND_CONTACT_METADATA generic_semantic_edges=",semantic_count," unverified_slatted_edges=",uncertain_slats)
	rider.free()


static func _normal_joint_refusals(check: Callable) -> void:
	var straight := Line.new("consistent_grade",PackedVector3Array([
		Vector3(0,2,0),Vector3(0,3,-4),Vector3(0,5,-12)]))
	straight.configure_contact(0.0,0.20,"original collinear beam segments")
	var constant_up:=Vector3.UP.slide(Vector3(0,1,-4).normalized()).normalized()
	var joint: float=straight.points[0].distance_to(straight.points[1])
	var accurate := straight.contact_verified
	for distance: float in [joint-0.04,joint,joint+0.04]:
		accurate=accurate and (straight.contact_at(distance)-straight.point_at(distance)).distance_to(constant_up*0.20)<0.00001
	check.call(accurate,
		"grind contact: same-direction collinear grades retain an exact constant beam normal through a subdivision")
	for points: PackedVector3Array in [
		PackedVector3Array([Vector3(0,2,0),Vector3(0,3,-4),Vector3(0,3,-8)]),
		PackedVector3Array([Vector3(0,2,0),Vector3(0,3,-4),Vector3(4,4,-4)]),
		PackedVector3Array([Vector3(0,2,0),Vector3(0,3,-4),Vector3(0,2,0)])]:
		var line:=Line.new("unsupported_joint",points)
		var before:=line.points.duplicate()
		var original_length: float=line.length
		for offsets: Vector2 in [Vector2(0.0,0.065),Vector2(-0.07,0.07)]:
			line.configure_contact(0.0,0.0,"previous direct-top authority")
			line.configure_contact(offsets.x,offsets.y,"unsupported radial joint")
			check.call(not line.contact_verified and line.contact_source.is_empty()
				and line.contact_vertical_offset==0.0 and line.contact_normal_offset==0.0
				and line.points==before and line.length==original_length
				and line.contact_at(line.length*0.5).is_equal_approx(line.point_at(line.length*0.5)),
				"grind contact: grade break, graded corner or reversing grade cannot certify an averaged beam/cylinder top "+str(points)+" "+str(offsets))
		line.configure_contact(-Edges.SKIN,0.0,"original direct top without admission skin")
		check.call(line.contact_verified
			and line.contact_at(joint).distance_to(line.point_at(joint)-Vector3.UP*Edges.SKIN)<0.00001,
			"grind contact: zero-normal source-top metadata retains its real polyline without inventing radial joint support")


static func _find(lines: Array,id: String) -> RefCounted:
	for line: RefCounted in lines:
		if String(line.id)==id: return line
	return null
