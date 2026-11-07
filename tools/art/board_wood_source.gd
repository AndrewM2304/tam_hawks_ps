@tool
extends RefCounted
## Pure source decoder; no Editor-only base or native mesh construction.
const SOURCE_SHA:="76103e39e5ed91c5c8381d38c58af8272915952f000ba475dbda30206b7d0943"
const EXPECTED_VERTICES:=1600
const EXPECTED_INDICES:=7800
func _sha(raw:PackedByteArray)->String:
 var context:=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(raw)
 return context.finish().hex_encode()
func decode_source(raw:PackedByteArray,expected_sha:String)->Dictionary:
 if raw.size()<28 or _sha(raw)!=expected_sha:return {}
 if raw.decode_u32(0)!=0x46546c67 or raw.decode_u32(4)!=2 or raw.decode_u32(8)!=raw.size():return {}
 var json_size:int=raw.decode_u32(12)
 if raw.decode_u32(16)!=0x4e4f534a or json_size<2 or 28+json_size>raw.size():return {}
 var parsed:Variant=JSON.parse_string(raw.slice(20,20+json_size).get_string_from_utf8())
 if not parsed is Dictionary:return {}
 var gltf:Dictionary=parsed
 var binary_at:int=20+json_size
 var binary_size:int=raw.decode_u32(binary_at)
 if raw.decode_u32(binary_at+4)!=0x004e4942 or binary_at+8+binary_size>raw.size():return {}
 var binary:PackedByteArray=raw.slice(binary_at+8,binary_at+8+binary_size)
 if not gltf.has("meshes") or gltf.meshes.size()!=1 or gltf.meshes[0].primitives.size()!=4:return {}
 var primitive:Dictionary=gltf.meshes[0].primitives[0]
 if int(primitive.get("mode",4))!=4 or int(primitive.material)!=0 or gltf.materials[0].name!="MapleAndRiverInk":return {}
 var attributes:Dictionary=primitive.attributes
 var decoded:Dictionary={}
 for key:String in ["POSITION","NORMAL","TEXCOORD_0","TANGENT"]:
  var width:int=2 if key=="TEXCOORD_0" else (4 if key=="TANGENT" else 3)
  if not attributes.has(key):return {}
  var result:Dictionary=_floats(gltf,binary,int(attributes[key]),width)
  if result.is_empty() or int(result.count)!=EXPECTED_VERTICES:return {}
  decoded[key]=result["values"]
 var points:=PackedVector3Array()
 var normals:=PackedVector3Array()
 var uv:=PackedVector2Array()
 points.resize(EXPECTED_VERTICES);normals.resize(EXPECTED_VERTICES);uv.resize(EXPECTED_VERTICES)
 for index:int in EXPECTED_VERTICES:
  points[index]=Vector3(decoded.POSITION[index*3],decoded.POSITION[index*3+1],decoded.POSITION[index*3+2])
  normals[index]=Vector3(decoded.NORMAL[index*3],decoded.NORMAL[index*3+1],decoded.NORMAL[index*3+2])
  uv[index]=Vector2(decoded.TEXCOORD_0[index*2],decoded.TEXCOORD_0[index*2+1])
  if not points[index].is_finite() or not normals[index].is_finite() or normals[index].length_squared()<.5 or not uv[index].is_finite():return {}
 var tangents:PackedFloat32Array=decoded.TANGENT
 for value:float in tangents:
  if not is_finite(value):return {}
 for index:int in EXPECTED_VERTICES:
  if absf(tangents[index*4+3])!=1.0:return {}
 var indices:PackedInt32Array=_indices(gltf,binary,int(primitive.indices))
 if indices.size()!=EXPECTED_INDICES:return {}
 # glTF is CCW; native Godot triangles are CW. Keep source normals/tangent W.
 for offset:int in range(0,indices.size(),3):
  var swap:int=indices[offset+1];indices[offset+1]=indices[offset+2];indices[offset+2]=swap
 for value:int in indices:
  if value<0 or value>=EXPECTED_VERTICES:return {}
 var arrays:Array=[]
 arrays.resize(Mesh.ARRAY_MAX)
 arrays[Mesh.ARRAY_VERTEX]=points;arrays[Mesh.ARRAY_NORMAL]=normals
 arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_TANGENT]=tangents
 arrays[Mesh.ARRAY_INDEX]=indices
 return {"arrays":arrays,"source_sha256":expected_sha}
func _span(gltf:Dictionary,binary:PackedByteArray,index:int,width:int,component:int,bytes_per:int)->Dictionary:
 if index<0 or index>=gltf.accessors.size():return {}
 var accessor:Dictionary=gltf.accessors[index]
 if accessor.has("sparse") or int(accessor.componentType)!=component:return {}
 var view_index:int=int(accessor.get("bufferView",-1))
 if view_index<0 or view_index>=gltf.bufferViews.size():return {}
 var view:Dictionary=gltf.bufferViews[view_index]
 if int(view.get("buffer",0))!=0 or int(view.get("byteStride",width*bytes_per))!=width*bytes_per:return {}
 var count:int=int(accessor.count)
 var inner:int=int(accessor.get("byteOffset",0))
 var begin:int=int(view.get("byteOffset",0))+inner
 var end:int=begin+count*width*bytes_per
 if count<=0 or count>EXPECTED_INDICES or inner<0 or begin<0 or end>binary.size() or inner+count*width*bytes_per>int(view.byteLength):return {}
 return {"begin":begin,"end":end,"count":count}
func _floats(gltf:Dictionary,binary:PackedByteArray,index:int,width:int)->Dictionary:
 var span:Dictionary=_span(gltf,binary,index,width,5126,4)
 if span.is_empty():return {}
 var accessor:Dictionary=gltf.accessors[index]
 if str(accessor.type)!=("VEC"+str(width)):return {}
 return {"count":span.count,"values":binary.slice(span.begin,span.end).to_float32_array()}
func _indices(gltf:Dictionary,binary:PackedByteArray,index:int)->PackedInt32Array:
 if index<0 or index>=gltf.accessors.size():return PackedInt32Array()
 var accessor:Dictionary=gltf.accessors[index]
 var component:int=int(accessor.componentType)
 if str(accessor.type)!="SCALAR" or component not in [5123,5125]:return PackedInt32Array()
 var bytes_per:int=2 if component==5123 else 4
 var span:Dictionary=_span(gltf,binary,index,1,component,bytes_per)
 if span.is_empty():return PackedInt32Array()
 var result:=PackedInt32Array();result.resize(span.count)
 for i:int in span.count:result[i]=binary.decode_u16(span.begin+i*2) if component==5123 else binary.decode_u32(span.begin+i*4)
 return result
