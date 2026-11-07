"""Bake cropped source maps and fit authentic eye/brow surfaces offline."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageOps

def bake(f, work, output):
    work, output = Path(work), Path(output)
    # Exact occupied head/chest islands; reserve padding before packing face detail.
    size=2048; mask=Image.new('L',(size,size));draw=ImageDraw.Draw(mask)
    _,uv,faces,_=f.parse_obj(f.ROOT/'game/art/assets/makehuman_hm08/head.obj')
    for face in faces:
     draw.polygon([tuple(uv[t]*[size-1,-(size-1)]+[0,size-1]) for v,t in face],fill=255)
    crop=np.load(work/'chest-crop.npz');chest_uv=crop['uv']
    for tri in crop['triangles']:
     draw.polygon([tuple(chest_uv[t]*[size-1,-(size-1)]+[0,size-1]) for t in tri],fill=255)
    # Full source atlas never enters the result: neutral unused areas remain neutral.
    source=Image.open(f.ROOT/'.local/downloads/mh_skin/young_lightskinned_male_diffuse.png').convert('RGB')
    canvas=Image.new('RGB',(size,size),(196,144,119));expanded=mask.filter(ImageFilter.MaxFilter(25));canvas.paste(source,(0,0),expanded)
    occupied=np.array(expanded)>0; layouts={};vertices,joints=f.adult()
    for name,source_image,objname,n in [('eyes','brownlight_eye.png','high-poly',512),('brows','eyebrow001.png','eyebrow001',256)]:
     im=Image.open(f.SOURCE/source_image).convert('RGBa').resize((n,n),Image.Resampling.LANCZOS).convert('RGBA')
     _,uv,faces,_=f.parse_obj(f.SOURCE/(objname+'.obj'));p,_=f.proxy(f.SOURCE/(objname+'.mhclo'),vertices);p-=joints['head']
     if name=='brows':
      a=np.array(im).astype(float);a[:,:,:3]=np.clip(a[:,:,:3]*1.6+[8,6,4],0,255);a[:,:,3]*=.65;im=Image.fromarray(a.astype('uint8'))
      im.save(output/'fitted_brows_albedo.png')
      layouts[name]={'source_obj':objname+'.obj','source_image':source_image,'separate_RGBA_map':'fitted_brows_albedo.png','size':[n,n],'reason':'Keep2KskinRGB/BC1; avoidwholeatlassparsealphaforcingBC3.'}
     else:
      extent=n+32;sums=np.pad(occupied.astype('int32'),((1,0),(1,0))).cumsum(0).cumsum(1);chosen=None
      for y in range(0,size-extent,16):
       for x in range(0,size-extent,16):
        if sums[y+extent,x+extent]-sums[y,x+extent]-sums[y+extent,x]+sums[y,x]==0:
         chosen=(x+16,y+16);break
       if chosen:break
      assert chosen,('No unused atlas rectangle',name)
      x,y=chosen;occupied[y-16:y+n+16,x-16:x+n+16]=True
      canvas.paste(im.convert('RGB'),(x,y))
      uv=np.stack([(x+uv[:,0]*n)/size,1-(y+(1-uv[:,1])*n)/size],axis=1)
      layouts[name]={'source_obj':objname+'.obj','source_image':source_image,'rectangle_xywh':[x,y,n,n],'padding_px':16,'vertices':len(p),'triangles':len(faces)}
     f.write_obj(output/f'fitted_{name}.obj',p,uv,faces)
    canvas.save(output/'head_albedo.png')
    # Delight source trainer photographic highlights into restrained charcoal albedo.
    shoe_size=1024
    a=np.asarray(Image.open(f.SOURCE/'shoes02_diffuse.png').convert('RGB').resize((shoe_size,shoe_size),Image.Resampling.LANCZOS)).astype(float)/255
    lum=a@np.array([.2126,.7152,.0722]);scale=.72+.56*lum
    base=np.array([.25,.27,.285]); shoe=scale[:,:,None]*base
    # The source tread occupies its own original upper strip: retain neutral rubber
    # construction contrast without importing its painted specular highlights.
    yy=np.arange(shoe_size)[:,None];rubber=(yy<shoe_size*142/512)
    shoe=np.where(rubber[:,:,None],(.70+.60*lum)[:,:,None]*np.array([.34,.35,.355]),shoe)
    Image.fromarray(np.clip(shoe*255,0,255).astype('uint8')).save(output/'fitted_shoe_albedo.png')
    (output/'face-atlas-layout.json').write_text(json.dumps({'size':size,'policy':'Existing skin UVs unchanged; opaque eyes use verified unoccupied RGB skin atlas region. Tiny brows use separate alpha map to preserve skinBC1 and avoidlargealphaVRAMincrease.','regions':layouts},indent=2)+'\n')
    # Compress only photographed diffuse highlights; physical specular response
    # remains the native hair material's responsibility, not a bright painted patch.
    hair=Image.open(f.SOURCE/'short02_diffuse.png').convert('RGBa').resize((1024,1024),Image.Resampling.LANCZOS).convert('RGBA')
    h=np.array(hair).astype(float)/255
    lum=h[:,:,:3]@np.array([.2126,.7152,.0722])
    dest=np.where(lum>.20,.20+.16*(1-np.exp(-(lum-.20)/.25)),lum)
    h[:,:,:3]*=(dest/np.maximum(lum,1e-6))[:,:,None]
    Image.fromarray(np.clip(h*255,0,255).astype('uint8')).save(output/'fitted_hair_albedo.png')

    v,j=f.adult();p,_=f.proxy(f.SOURCE/'high-poly.mhclo',v);p-=j['head']
    _,uv,faces,_=f.parse_obj(f.SOURCE/'high-poly.obj')
    a=np.asarray(Image.open(f.SOURCE/'brownlight_eye.png').convert('RGBA'))
    # Native source has two completely transparent outer corneal shells. Their UVs
    # deliberately address the fully alpha-zero black reserve circle. An opaque RGB
    # atlas cannot represent those shells; retire only whole zero-alpha components,
    # retaining the actual source iris/sclera geometry and its black pupil.
    adj={i:set() for i in range(len(p))}
    for face in faces:
     for i,_ in face:adj[i].update(k for k,_ in face if i!=k)
    seen=set();discard=set();components=[]
    for first in range(len(p)):
     if first in seen:continue
     ids={first};stack=[first]
     while stack:
      k=stack.pop()
      for n in adj[k]:
       if n not in ids:ids.add(n);stack.append(n)
     seen.update(ids)
     member=[i for i,face in enumerate(faces) if face[0][0] in ids]
     coords=uv[[t for i in member for _,t in faces[i]]]
     pix=a[np.rint((1-coords[:,1])*(a.shape[0]-1)).astype(int),np.rint(coords[:,0]*(a.shape[1]-1)).astype(int)]
     if np.all(pix[:,3]==0):discard.update(member)
     components.append({'source_vertices':sorted(ids),'source_triangles':member,'alpha_min':int(pix[:,3].min()),'alpha_max':int(pix[:,3].max()),'retained':not np.all(pix[:,3]==0)})
    keep=[i for i in range(len(faces)) if i not in discard]
    assert len(discard)==980 and len(keep)==1060
    layout=json.loads((output/'face-atlas-layout.json').read_text());x,y,w,_=layout['regions']['eyes']['rectangle_xywh'];size=layout['size']
    layout['regions']['eyes']['source_all_triangles']=len(faces)
    layout['regions']['eyes']['native_retained_triangles']=len(keep)
    (output/'face-atlas-layout.json').write_text(json.dumps(layout,indent=2)+'\n')
    newuv=np.stack([(x+uv[:,0]*w)/size,1-(y+(1-uv[:,1])*w)/size],axis=1)
    f.write_obj(output/'fitted_eyes.obj',p,newuv,[faces[i] for i in keep])
    (output/'eye-source-selection.json').write_text(json.dumps({'policy':'Retain actual opaque iris/sclera components; omit only entire fully-alpha-zero source corneal shells before RGB-atlas conversion. Native material clearcoat supplies restrained corneal specular response without opaque black shell occlusion.','retained_source_triangle_indices':keep,'components':components},indent=2)+'\n')

    # Source cloth padding is filled before resize so transparent margins never
    # turn into dark mip borders. Preserve original construction/crease detail.
    rgba = np.asarray(Image.open(f.SOURCE / "male_casualsuit01_diffuse.png").convert("RGBA")).copy()
    mask = rgba[:, :, 3] > 8
    for _ in range(10):
        previous = mask.copy()
        for axis in (0, 1):
            for direction in (-1, 1):
                neighbor = np.roll(previous, direction, axis)
                added = ~mask & neighbor
                rgba[added] = np.roll(rgba, direction, axis)[added]
                mask |= added
    Image.fromarray(rgba[:, :, :3]).resize((1024, 1024), Image.Resampling.LANCZOS).save(output / "fitted_cloth_albedo.png")
    normal = np.asarray(Image.open(f.SOURCE / "male_casualsuit01_normal.png").resize((512, 512), Image.Resampling.LANCZOS)).astype(float) / 127.5 - 1
    normal /= np.maximum(np.linalg.norm(normal, axis=2)[:, :, None], 1e-10)
    Image.fromarray(np.clip((normal + 1) * 127.5, 0, 255).astype("uint8")).save(output / "fitted_cloth_normal.png")

    # The caller's live colour is authoritative for player customisation and
    # NPC identity. Preserve construction detail in neutral maps; never replace
    # the passed material with a fixed blue asset material.
    for name, gain in (("fitted_cloth_albedo.png", 2.7), ("fitted_shoe_albedo.png", 3.5)):
        image = Image.open(output / name).convert("RGB")
        ImageEnhance.Brightness(ImageOps.grayscale(image)).enhance(gain).convert("RGB").save(output / name)
    (output / "palette-map.json").write_text(json.dumps({
        "policy":"Neutral source construction detail; actual caller-owned shirt/denim colours remain live. Footwear duplicates caller materials to avoid overwriting shared clothing maps.",
        "cloth_grayscale_brightness_gain":2.7,"shoe_grayscale_brightness_gain":3.5,
        "shoe_resolution":1024,"hand_albedo_resolution":512,
        "budget_policy":"Pack each real palm/nail UV island with positive uniform material UV scale/offset and repeat inside512; retain original mesh streams and increase effective texel density versus1024fullatlas. Restore real1Kshoe detail and allow shared512NPC vest/reflector maps inside64MiB combined conservative RGBA mip budget. Native matched image admission required."},indent=2)+"\n")
