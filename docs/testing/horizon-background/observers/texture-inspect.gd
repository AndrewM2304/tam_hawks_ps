extends SceneTree
func _initialize()->void:
 var t=load("res://game/art/assets/horizon/glasgow_horizon.png")
 var im:Image=t.get_image()
 print("TEXTURE path=",t.resource_path," format=",im.get_format()," data=",im.get_data().size()," mipmaps=",im.get_mipmap_count())
 FileAccess.open("res://.local/horizon-background/native-dxt1.bin",FileAccess.WRITE).store_buffer(im.get_data())
 if im.is_compressed():im.decompress()
 var largest:=0.0
 for y:int in range(0,im.get_height(),32):
  var a:Color=im.get_pixel(0,y)
  var b:Color=im.get_pixel(im.get_width()-1,y)
  var delta:=Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length()
  if delta>largest:largest=delta;print("SEAM y=",y," a=",a," b=",b," delta=",delta)
 im.save_png("res://.local/horizon-background/native-decoded.png")
 quit()
