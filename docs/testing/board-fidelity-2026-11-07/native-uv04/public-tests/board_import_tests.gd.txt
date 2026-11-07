extends RefCounted
## Native UV import regressions: source authentication, real compression and RGB
## allocation mistakes. No trajectory or player contact simulation is duplicated.
const Policy=preload("res://tools/art/board_wood_source.gd")
const SOURCE_PATH:="res://game/art/assets/tam_skateboard/tam_skateboard.glb"
const MATERIALS:Array[String]=["MapleAndRiverInk","Griptape","CastAluminium","Urethane"]
const PROTECTED_NATIVE={"Griptape":{"positions":"44c0ba1d8a353e478fd4be9dce985f14494a52405e2e4c5f3b36f3b4c9a30bbe","normals":"5b70cae76b7b2015981eafef85c77f48c7debff9ef7abd53fb20e412a6f875ef","uv":"14de93fecd0388d185987455fb63e99c4c6d65aa6c9dade7586904a5c1eb1035","tangents":"13d3bea90124e7209fedb5c8b79485e5ae286c1046929dfeeb79ede82ee56ec1","indices":"5ecc7e3f08d4bb4cc72171438f78a490e1fea083963b1bcefbc09713825a6816"},"CastAluminium":{"positions":"db9f741a20e6fa5e6708f6884157e5731b23625b1c61f28298a4222895287e72","normals":"111ee126a56113feffe8d799f2039975f5f75a5b26645cd297161b98160e0951","uv":"d816ede87fb81c5c65835afe806b1a70ed9437eab1cff3bac00f4b43bb0c345d","tangents":"803574f8f69492156a847a515822b9467e4e4a047024dbdbd301f54980fd3496","indices":"4608f53d5be36a68b78f85e79114b4ff9be65411ad0e1254c285c7b03c3688cd"},"Urethane":{"positions":"8bb4f816793a403aa3b665880beb0253631625046f6647b49b472d8e50c35f14","normals":"47d170c8d61885ae4c486d4d53ca7106eb19b5d3d3f3e28b8dc5f0f658b60ee2","uv":"0d4e629a1ee7082d6289ecc14860ce2b5e6be41742895bf9b5badf86d554aa33","tangents":"922a3110254596b908c7c5289c30c087cfdca29b368dd76b3381c05dd0cc46cb","indices":"cfb786ef3d5a68bb4ccc4a40337f1fa747972f26fecf63c057abf6a547044ee9"}}
static func run(check:Callable,source_path:String=SOURCE_PATH)->void:
 _source_controls(check,source_path)
 var scene:PackedScene=load(source_path) as PackedScene
 check.call(scene!=null,"board import actual source PackedScene loads")
 if scene==null:return
 var model:Node3D=scene.instantiate() as Node3D
 var meshes:Array[MeshInstance3D]=[]
 _collect(model,meshes)
 check.call(meshes.size()==1,"board import exactly one native mesh node")
 if meshes.size()!=1:model.free();return
 var node:MeshInstance3D=meshes[0]
 var mesh:ArrayMesh=node.mesh as ArrayMesh
 check.call(model.transform==Transform3D.IDENTITY and node.transform==Transform3D.IDENTITY,"board import protected identity model/mesh frames")
 check.call(mesh!=null and mesh.get_surface_count()==4,"board import four native material surfaces")
 if mesh==null or mesh.get_surface_count()!=4:model.free();return
 var meta:Dictionary=model.get_meta("tam_board_wood_import",{})
 check.call(meta.get("source_sha256","")==Policy.SOURCE_SHA and meta.get("policy_sha256","")==FileAccess.get_sha256("res://tools/art/import_board_wood.gd") and meta.get("decoder_sha256","")==FileAccess.get_sha256("res://tools/art/board_wood_source.gd"),"board import executed source/policy/decoder pins match installed files")
 var texture_ids:Dictionary={}
 var triangles:int=0
 for surface:int in mesh.get_surface_count():
  var material:StandardMaterial3D=mesh.surface_get_material(surface) as StandardMaterial3D
  check.call(material!=null and material.resource_name==MATERIALS[surface],"board import native material identity "+str(surface))
  if material==null:continue
  if material.albedo_texture!=null:texture_ids[material.albedo_texture.get_instance_id()]=material.albedo_texture
  var arrays:Array=mesh.surface_get_arrays(surface)
  var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
  triangles+=indices.size()/3
  if surface==0:
   var uv:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
   var nondegenerate:bool=uv.size()==points.size() and indices.size()==7800
   for i:int in range(0,indices.size(),3):
    var a:Vector2=uv[indices[i]];var e:Vector2=uv[indices[i+1]]-a;var f:Vector2=uv[indices[i+2]]-a
    nondegenerate=nondegenerate and a.is_finite() and e.is_finite() and f.is_finite() and absf(e.cross(f))*.5>1e-12
   check.call(nondegenerate,"board import all2600wood UV triangles finite and nondegenerate")
   check.call((mesh.surface_get_format(0)&Mesh.ARRAY_FLAG_COMPRESS_ATTRIBUTES)==0,"board import wood positions protected from lossy compression")
   var source:Dictionary=Policy.new().decode_source(FileAccess.get_file_as_bytes(source_path),Policy.SOURCE_SHA)
   check.call(not source.is_empty() and _points_equal(points,source.arrays[Mesh.ARRAY_VERTEX]),"board import native wood position multiset exact to actual pinned source")
  else:
   var expected:Dictionary=PROTECTED_NATIVE[MATERIALS[surface]]
   var slots:Dictionary={"positions":Mesh.ARRAY_VERTEX,"normals":Mesh.ARRAY_NORMAL,"uv":Mesh.ARRAY_TEX_UV,"tangents":Mesh.ARRAY_TANGENT,"indices":Mesh.ARRAY_INDEX}
   var unchanged:bool=true
   for name:String in slots:unchanged=unchanged and _sha(arrays[slots[name]].to_byte_array())==expected[name]
   check.call(unchanged,"board import protected native grip/hardware streams exact "+str(surface))
   if surface==1:check.call(absf(_lowest(points)-.017)<.000001,"board import actual grip-centre datum retained")
   if surface==3:check.call(absf(_lowest(points)+.12)<.000001,"board import actual wheel-bottom datum retained")
 check.call(triangles==5696,"board import5696actual indexed triangles retained")
 check.call(texture_ids.size()==1,"board import all four materials share one native atlas")
 if texture_ids.size()==1:
  var texture:Texture2D=texture_ids.values()[0]
  var image:Image=texture.get_image()
  check.call(image!=null and texture.get_width()==1024 and texture.get_height()==1024 and image.get_format()==Image.FORMAT_RGB8 and image.get_mipmap_count()==10 and image.get_data().size()==4194303,"board import actual bound atlas RGB8+mips allocation retained")
 model.free()
static func _collect(node:Node,meshes:Array[MeshInstance3D])->void:
 if node is MeshInstance3D:meshes.append(node)
 for child:Node in node.get_children():_collect(child,meshes)
static func _sha(bytes:PackedByteArray)->String:
 var context:=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(bytes);return context.finish().hex_encode()
static func _points_equal(a:PackedVector3Array,b:PackedVector3Array)->bool:
 if a.size()!=b.size():return false
 var counts:Dictionary={}
 for point:Vector3 in a:counts[point]=counts.get(point,0)+1
 for point:Vector3 in b:
  if not counts.has(point) or counts[point]<=0:return false
  counts[point]-=1
 return true
static func _lowest(points:PackedVector3Array)->float:
 var result:float=INF
 for point:Vector3 in points:result=minf(result,point.y)
 return result
static func _source_controls(check:Callable,source_path:String)->void:
 var policy:RefCounted=Policy.new()
 var source:PackedByteArray=FileAccess.get_file_as_bytes(source_path)
 var decoded:Dictionary=policy.decode_source(source,Policy.SOURCE_SHA)
 check.call(not decoded.is_empty() and decoded.arrays[Mesh.ARRAY_VERTEX].size()==1600,"source policy actual pinned raw wood decodes")
 check.call(policy.decode_source(source,"0".repeat(64)).is_empty(),"source policy wrong source pin refuses before geometry")
 var altered:PackedByteArray=source.duplicate()
 altered[altered.size()-10]^=1
 check.call(policy.decode_source(altered,Policy.SOURCE_SHA).is_empty(),"source policy changed source bytes refuse original pin")
 var json_size:int=source.decode_u32(12)
 var json_data:Dictionary=JSON.parse_string(source.slice(20,20+json_size).get_string_from_utf8())
 var binary_start:int=20+json_size+8
 var binary:PackedByteArray=source.slice(binary_start,binary_start+source.decode_u32(20+json_size))
 var layout:Dictionary=json_data.duplicate(true)
 layout.meshes[0].primitives[0].material=1
 var wrong_layout:PackedByteArray=_pack(layout,binary)
 check.call(policy.decode_source(wrong_layout,policy._sha(wrong_layout)).is_empty(),"source policy rehashed wrong primitive layout refuses")
 var stride:Dictionary=json_data.duplicate(true)
 var position_index:int=int(stride.meshes[0].primitives[0].attributes.POSITION)
 stride.bufferViews[int(stride.accessors[position_index].bufferView)]["byteStride"]=16
 var wrong_stride:PackedByteArray=_pack(stride,binary)
 check.call(policy.decode_source(wrong_stride,policy._sha(wrong_stride)).is_empty(),"source policy rehashed unsupported interleaving refuses")
 var nonfinite:PackedByteArray=binary.duplicate()
 var accessor:Dictionary=json_data.accessors[position_index]
 var at:int=int(json_data.bufferViews[int(accessor.bufferView)].get("byteOffset",0))+int(accessor.get("byteOffset",0))
 nonfinite.encode_float(at,NAN)
 var bad_position:PackedByteArray=_pack(json_data,nonfinite)
 check.call(policy.decode_source(bad_position,policy._sha(bad_position)).is_empty(),"source policy rehashed nonfinite actual source position refuses")
 var bad_indices:PackedByteArray=binary.duplicate()
 var index_accessor:Dictionary=json_data.accessors[int(json_data.meshes[0].primitives[0].indices)]
 var index_at:int=int(json_data.bufferViews[int(index_accessor.bufferView)].get("byteOffset",0))+int(index_accessor.get("byteOffset",0))
 if int(index_accessor.componentType)==5123:bad_indices.encode_u16(index_at,65535)
 else:bad_indices.encode_u32(index_at,65535)
 var invalid_index:PackedByteArray=_pack(json_data,bad_indices)
 check.call(policy.decode_source(invalid_index,policy._sha(invalid_index)).is_empty(),"source policy rehashed out-of-range source index refuses")
static func _pack(gltf:Dictionary,binary:PackedByteArray)->PackedByteArray:
 var json_bytes:PackedByteArray=JSON.stringify(gltf,"",true,true).to_utf8_buffer()
 while json_bytes.size()%4:json_bytes.append(32)
 var result:=PackedByteArray();result.resize(20)
 result.encode_u32(0,0x46546c67);result.encode_u32(4,2)
 result.encode_u32(8,28+json_bytes.size()+binary.size())
 result.encode_u32(12,json_bytes.size());result.encode_u32(16,0x4e4f534a)
 result.append_array(json_bytes)
 var offset:int=result.size();result.resize(offset+8)
 result.encode_u32(offset,binary.size());result.encode_u32(offset+4,0x004e4942)
 result.append_array(binary)
 return result
