from pathlib import Path
from PIL import Image,ImageDraw
import json,math,hashlib
R=Path('/workspace/tam_hawks_ps');P=R/'.local/qa-fidelity/native-review/forecast-192-side-02';m=json.loads((P/'manifest.json').read_text());rows=[]
for row in m['frames']:
 im=Image.open(P/row['file']).convert('RGBA');points=[]
 for y in range(250,400):
  for x in range(500,800):
   r,g,b,a=im.getpixel((x,y))
   if r<80 and g>r+5 and b>r+10:points.append((x+.5,y+.5))
 rows.append({'file':row['file'],'physics':row['state']['physics_frame'],'phase_step':row['phase_step'],'darkblue_pixels':len(points),'centroid':[sum(v[i] for v in points)/len(points) for i in range(2)],'offset_m':row['state']['presentation_offset']})
steps=[{'before':a['file'],'after':b['file'],'dx_px':b['centroid'][0]-a['centroid'][0],'dy_px':b['centroid'][1]-a['centroid'][1],'distance_px':math.dist(a['centroid'],b['centroid']),'offset_step_m':math.dist(a['offset_m'],b['offset_m'])} for a,b in zip(rows,rows[1:])]
report={'method':'Same fixed darkblue-region mask as prior retained diagnostic: x[500,800),y[250,400),R<80/G>R+5/B>R+10, nativepixelcentres. Region motion is not exact whole-body COM or tracked corresponding geometry.','rows':rows,'steps':steps,'crown_010_to_011':steps[10],'largest_crown_000_to_013':max(steps[:13],key=lambda x:abs(x['dx_px'])),'largest32_horizontal':max(steps,key=lambda x:abs(x['dx_px'])),'limits':'Older observed28.627px film used a standalone80.1setup; this full-prefix film is not a matched-camera/complete-state A/B. Native physical parity is separately exact against the retained full four-case reactive trace. Shape/posture/bank-return rotation also affects the mask centroid.'}
(P/'image-motion-analysis.json').write_text(json.dumps(report,indent=2)+'\n');print({k:v for k,v in report.items() if k not in ['rows','steps']})
# Unscaled four-frame concatenations are review derivatives only. Every source
# pixel remains intact; these do not replace native single-image proofs.
for group in range(8):
 sheet=Image.new('RGB',(2560,1664),'white');draw=ImageDraw.Draw(sheet)
 for i in range(4):
  index=group*4+i;im=Image.open(P/f'frames/side-{index:03}.png').convert('RGB');x=(i%2)*1280;y=(i//2)*832;draw.text((x+12,y+8),f'Native side {index:03}; full-prefix phase{144+index}; unscaled original pixels',fill='black');sheet.paste(im,(x,y+32))
 sheet.save(R/f'.local/qa-fidelity/forecast-sheet-{group}.jpg',quality=95)
