extends RefCounted
## Startup-only batching of explicitly registered, immutable architectural art.
## Authored CPU records are authoritative: headless MultiMesh readback is dummy.
## Registration promises that ancestor transforms/visibility stay static after
## finalize(). Gameplay, collision, trees and unregistered visuals are untouched.

const META_RECORDS: StringName = &"tam_static_batch_records"
const META_PERMISSION: StringName = &"tam_static_batch_permission"
const META_FINALIZED: StringName = &"tam_static_batch_finalized"
const META_STATIC_SCOPE: StringName = &"static_batch_scope"


static func register(source: MultiMeshInstance3D, transforms: Array,
		colors: Array = [], custom_data: Array = []) -> bool:
	if source == null:
		return false
	source.set_meta(META_PERMISSION, false)
	var batch: MultiMesh = source.multimesh
	if batch == null or transforms.size() != batch.instance_count or transforms.is_empty():
		return false
	if (batch.use_colors and colors.size() != transforms.size()) \
		or (not batch.use_colors and not colors.is_empty()) \
		or (batch.use_custom_data and custom_data.size() != transforms.size()) \
		or (not batch.use_custom_data and not custom_data.is_empty()):
		return false
	for value: Variant in transforms:
		if not value is Transform3D or not _finite_transform(value):
			return false
	for channel: Array in [colors, custom_data]:
		for value: Variant in channel:
			if not value is Color or not _finite_color(value):
				return false
	source.set_meta(META_RECORDS, {"transforms": transforms.duplicate(),
		"colors": colors.duplicate(), "custom_data": custom_data.duplicate(),
		"multimesh_id": batch.get_instance_id(), "use_colors": batch.use_colors,
		"use_custom_data": batch.use_custom_data})
	source.set_meta(META_PERMISSION, true)
	return true


static func authored_transforms(source: MultiMeshInstance3D) -> Array:
	return _records(source).get("transforms", []).duplicate()


static func snapshot(world: Node3D) -> Array[Dictionary]:
	# This is a CPU preservation receipt, not a claim about GPU buffer readback.
	var result: Array[Dictionary] = []
	for source: MultiMeshInstance3D in _registered(world):
		var records := _records(source)
		if records.is_empty() or source.multimesh == null:
			continue
		var state := _render_state(source)
		state[&"visible_in_tree"] = source.is_visible_in_tree()
		state[&"visible_instance_count"] = source.multimesh.visible_instance_count
		for index: int in range(records.transforms.size()):
			result.append({"transform": source.global_transform * records.transforms[index],
				"mesh": source.multimesh.mesh, "render_state": state,
				"use_colors": records.use_colors, "use_custom_data": records.use_custom_data,
				"color": records.colors[index] if records.use_colors else Color.WHITE,
				"custom_data": records.custom_data[index] if records.use_custom_data else Color(0, 0, 0, 0)})
	return result


static func finalize(world: Node3D, cell_size: float = 64.0) -> Dictionary:
	var report := {"cell_size": cell_size, "registered_sources": 0, "eligible_sources": 0,
		"excluded_sources": 0, "families_merged": 0, "families_without_saving": 0,
		"sources_removed": 0, "batches_created": 0, "instances_preserved": 0,
		"validation_failures": 0, "valid_configuration": false}
	if world == null or not world.is_inside_tree() or not is_finite(cell_size) \
		or cell_size < 8.0 or cell_size > 256.0 or not _finite_transform(world.global_transform):
		return report
	report.valid_configuration = true
	var families: Dictionary = {}
	for source: MultiMeshInstance3D in _registered(world):
		if bool(source.get_meta(META_FINALIZED, false)):
			continue
		report.registered_sources += 1
		if not _eligible(source, world, cell_size):
			report.excluded_sources += 1
			continue
		report.eligible_sources += 1
		var state := _render_state(source)
		var batch := source.multimesh
		var key: Array = [batch.mesh, batch.use_colors, batch.use_custom_data, state]
		if not families.has(key):
			families[key] = {"sources": [], "cells": {}}
		var family: Dictionary = families[key]
		family.sources.append(source)
		var records := _records(source)
		for index: int in range(records.transforms.size()):
			var transform: Transform3D = source.global_transform * records.transforms[index]
			var cell := Vector2i(floori(transform.origin.x / cell_size), floori(transform.origin.z / cell_size))
			if not family.cells.has(cell):
				family.cells[cell] = []
			family.cells[cell].append({"transform": transform,
				"color": records.colors[index] if batch.use_colors else Color.WHITE,
				"custom_data": records.custom_data[index] if batch.use_custom_data else Color(0, 0, 0, 0)})
	for key: Array in families:
		var family: Dictionary = families[key]
		# A smaller culling cell can add draws. Require a strict batch-node saving
		# for every exact mesh/material/render-state family before committing it.
		if family.cells.size() >= family.sources.size():
			report.families_without_saving += 1
			continue
		var staged: Array[MultiMeshInstance3D] = []
		var prototype: MultiMeshInstance3D = family.sources[0]
		var preserved := 0
		var valid := true
		for cell: Vector2i in family.cells:
			var records: Array = family.cells[cell]
			var anchor := Transform3D(Basis.IDENTITY, Vector3(cell.x * cell_size, 0, cell.y * cell_size))
			var batch := MultiMesh.new()
			batch.transform_format = MultiMesh.TRANSFORM_3D
			batch.use_colors = prototype.multimesh.use_colors
			batch.use_custom_data = prototype.multimesh.use_custom_data
			batch.mesh = prototype.multimesh.mesh
			batch.instance_count = records.size()
			var transforms: Array = []
			var colors: Array = []
			var custom: Array = []
			for index: int in range(records.size()):
				var local: Transform3D = anchor.affine_inverse() * records[index].transform
				transforms.append(local)
				batch.set_instance_transform(index, local)
				if batch.use_colors:
					colors.append(records[index].color)
					batch.set_instance_color(index, records[index].color)
				if batch.use_custom_data:
					custom.append(records[index].custom_data)
					batch.set_instance_custom_data(index, records[index].custom_data)
			# Duplicate all visual settings, rather than dropping an obscure render
			# flag in a handwritten copy. Eligible sources are childless and static.
			var output := prototype.duplicate(0) as MultiMeshInstance3D
			output.name = "StaticDecor_%d_%d_%d" % [report.families_merged, cell.x, cell.y]
			output.multimesh = batch
			world.add_child(output)
			output.global_transform = anchor
			valid = register(output, transforms, colors, custom) and valid
			output.set_meta(META_FINALIZED, true)
			valid = _render_state(output) == _render_state(prototype) and valid
			for index: int in range(records.size()):
				valid = _same_transform(output.global_transform * transforms[index], records[index].transform) and valid
			staged.append(output)
			preserved += records.size()
		if not valid:
			for output: MultiMeshInstance3D in staged:
				output.free()
			report.validation_failures += 1
			continue
		for source: MultiMeshInstance3D in family.sources:
			source.free()
		report.families_merged += 1
		report.sources_removed += family.sources.size()
		report.batches_created += staged.size()
		report.instances_preserved += preserved
	return report


static func _registered(node: Node) -> Array[MultiMeshInstance3D]:
	var result: Array[MultiMeshInstance3D] = []
	if node is MultiMeshInstance3D and bool(node.get_meta(META_PERMISSION, false)):
		result.append(node)
	for child: Node in node.get_children():
		result.append_array(_registered(child))
	return result


static func _records(source: MultiMeshInstance3D) -> Dictionary:
	if source == null or not bool(source.get_meta(META_PERMISSION, false)):
		return {}
	var records: Variant = source.get_meta(META_RECORDS, {})
	return records if records is Dictionary else {}


static func _eligible(source: MultiMeshInstance3D, world: Node3D, cell_size: float) -> bool:
	var batch := source.multimesh
	var records := _records(source)
	if batch == null or batch.mesh == null or records.is_empty() or source.get_script() != null \
		or source.get_child_count() != 0 or not source.is_visible_in_tree() or source.top_level \
		or batch.transform_format != MultiMesh.TRANSFORM_3D or batch.visible_instance_count != -1 \
		or batch.custom_aabb != AABB() or source.custom_aabb != AABB() \
		or source.visibility_parent != NodePath("") or source.transparency != 0.0 \
		or source.visibility_range_begin != 0.0 or source.visibility_range_end != 0.0 \
		or source.visibility_range_begin_margin != 0.0 or source.visibility_range_end_margin != 0.0 \
		or source.visibility_range_fade_mode != 0 or not _finite_transform(source.global_transform):
		return false
	if records.get("multimesh_id", -1) != batch.get_instance_id() \
		or records.transforms.size() != batch.instance_count \
		or records.use_colors != batch.use_colors or records.use_custom_data != batch.use_custom_data:
		return false
	for local: Transform3D in records.transforms:
		var global: Transform3D = source.global_transform * local
		if not _finite_transform(global) or absf(global.origin.x / cell_size) > 2147483000.0 \
			or absf(global.origin.z / cell_size) > 2147483000.0:
			return false
	if not _opaque_material(source.material_override) or not _opaque_material(source.material_overlay):
		return false
	if source.material_override == null:
		for surface: int in range(batch.mesh.get_surface_count()):
			if not _opaque_material(batch.mesh.surface_get_material(surface)):
				return false
	var ancestor: Node = source.get_parent()
	while ancestor != null and ancestor != world:
		if ancestor is PhysicsBody3D and not ancestor is StaticBody3D:
			return false
		if ancestor.get_script() != null and not bool(ancestor.get_meta(META_STATIC_SCOPE, false)):
			return false
		if ancestor is Node3D and ancestor.visibility_parent != NodePath(""):
			return false
		for child: Node in ancestor.get_children():
			if child is AnimationPlayer or child is AnimationTree:
				return false
		ancestor = ancestor.get_parent()
	return ancestor == world


static func _opaque_material(material: Material, seen: Dictionary = {}) -> bool:
	if material == null:
		return true
	if not material is BaseMaterial3D or seen.has(material.get_instance_id()):
		return false
	seen[material.get_instance_id()] = true
	if material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
		or material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED \
		or material.distance_fade_mode != BaseMaterial3D.DISTANCE_FADE_DISABLED \
		or material.proximity_fade_enabled:
		return false
	return _opaque_material(material.next_pass, seen)


static func _render_state(source: MultiMeshInstance3D) -> Dictionary:
	var state: Dictionary = {}
	for owner_class: StringName in [&"VisualInstance3D", &"GeometryInstance3D"]:
		for property: Dictionary in ClassDB.class_get_property_list(owner_class, true):
			if int(property.usage) & PROPERTY_USAGE_STORAGE:
				state[property.name] = source.get(property.name)
	return state


static func _finite_transform(value: Transform3D) -> bool:
	return value.origin.is_finite() and value.basis.x.is_finite() and value.basis.y.is_finite() \
		and value.basis.z.is_finite() and is_finite(value.basis.determinant()) \
		and value.basis.determinant() > 0.000001


static func _finite_color(value: Color) -> bool:
	return is_finite(value.r) and is_finite(value.g) and is_finite(value.b) and is_finite(value.a)


static func _same_transform(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) < 0.0001 and a.basis.x.distance_to(b.basis.x) < 0.0001 \
		and a.basis.y.distance_to(b.basis.y) < 0.0001 and a.basis.z.distance_to(b.basis.z) < 0.0001
