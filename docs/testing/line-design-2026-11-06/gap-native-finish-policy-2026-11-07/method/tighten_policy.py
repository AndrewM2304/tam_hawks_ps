from pathlib import Path
O=Path(__file__).resolve().parent;P=O/'project';E=O/'policy-positive-02/executed-policy-sources';E.mkdir(exist_ok=False)
for n in ['game/main.gd','game/tricks/gap_tracker.gd','game/tricks/native_gap_finish.gd','game/levels/glasgow_square.gd','game/levels/outdoor_routes.gd','game/levels/clyde_cable_line.gd']:
 q=E/(n+'.txt');q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes((P/n).read_bytes())
p=P/'game/tricks/native_gap_finish.gd';s=p.read_text().replace('var _targets:Dictionary={}\n','var _targets:Dictionary={}\nvar _gap_signatures:Dictionary={}\n')
s=s.replace('_targets.clear();_lines.clear();native_queries=0','_targets.clear();_lines.clear();_gap_signatures.clear();native_queries=0')
needle=' _ray.collision_mask=1|2';assert s.count(needle)==1
s=s.replace(needle,''' var definitions:Array=world.get_gap_definitions()
 for definition:Dictionary in definitions:
  if definition.get("finish_kind","")!="native_grind":continue
  if not definition.has_all(["id","name","start","end","radius","points","airborne_required","finish_destination"])or not _targets.has(definition.finish_destination)or not definition.airborne_required or _gap_signatures.size()>=16:return _refuse("invalid authored finish declaration")
  var signature:Dictionary=definition.duplicate(true)
  var route:Vector3=definition.end-definition.start
  signature["direction"]=route/route.length()
  _gap_signatures[definition.id]=signature
'''+needle)
needle=' for shape:Dictionary in owner.shapes:\n  var node:Variant=_object(shape.node)';assert s.count(needle)==1
s=s.replace(needle,''' for shape:Dictionary in owner.shapes:
  if typeof(shape.get("index"))!=TYPE_INT or int(shape.index)<0 or int(shape.index)>=int(owner.shape_count)or typeof(shape.get("rid"))!=TYPE_RID or not shape.get("frame")is Transform3D or not shape.get("size")is Vector3:return false
  var node:Variant=_object(shape.node)''')
needle='func _finish_ready(definition:Dictionary,from:Vector3,to:Vector3)->bool:\n';assert s.count(needle)==1
s=s.replace(needle,needle+''' if not definition.has_all(["id","finish_kind","finish_destination"])or typeof(definition.id)!=TYPE_STRING or not _gap_signatures.has(definition.id):return false
 var signature:Dictionary=_gap_signatures[definition.id]
 for key:Variant in signature:
  if not definition.has(key)or definition[key]!=signature[key]:return false
 if not _pending.has_all(["used","epoch","serial","frame","line","line_instance","raw_id","target","from","to","proof"])or typeof(_pending.used)!=TYPE_BOOL:return false
 for field:String in ["epoch","serial","frame","line_instance"]:
  if typeof(_pending[field])!=TYPE_INT:return false
 if _pending.serial!=_capture_serial or not _pending.proof is Dictionary or typeof(_pending.proof.get("rid"))!=TYPE_RID or typeof(_pending.proof.get("shape"))!=TYPE_INT:return false
''')
p.write_text(s)
print('Private type/signature/serial guards added; original46 positive sources retained verbatim.')
