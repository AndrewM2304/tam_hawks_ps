extends SceneTree
## Decode saved native PNGs with the same installed engine; no image synthesis.
func _initialize()->void:
	var failures:Array=[]
	var decoded:Array=[]
	for folder:String in OS.get_cmdline_user_args():
		var before:=decoded.size()
		for name:String in DirAccess.get_files_at(folder):
			if not name.ends_with(".png"):continue
			var path:=folder.path_join(name)
			var picture:=Image.new()
			if picture.load(path)!=OK or picture.is_empty():failures.append(path);continue
			decoded.append({"file":path,"width":picture.get_width(),"height":picture.get_height(),"format":picture.get_format(),"pixel_bytes":picture.get_data().size(),"sha256":FileAccess.get_sha256(path)})
		if decoded.size()==before:failures.append(folder+": no PNG evidence")
	print("PNG_AUDIT ",JSON.stringify({"decoded":decoded,"failures":failures}))
	print("RESULT: ",decoded.size()," passed, ",failures.size()," failed")
	quit(0 if failures.is_empty() and not decoded.is_empty() else 1)
