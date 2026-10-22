extends "res://docs/testing/camera-flow/observers/capture.gd"
## Labelled current-source graphical review, never used for timing admission.
func _initialize()->void:
	root.title="CURRENT CAMERA — single skater-relative ramp orbit"
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP,true)
	var layer:=CanvasLayer.new()
	layer.layer=100
	root.add_child(layer)
	var panel:=PanelContainer.new()
	panel.position=Vector2(310,16)
	panel.size=Vector2(550,38)
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	var label:=Label.new()
	label.text="CURRENT CAMERA · single local ramp orbit"
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",18)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	super._initialize()
