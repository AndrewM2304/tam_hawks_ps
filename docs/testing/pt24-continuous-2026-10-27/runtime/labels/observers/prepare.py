"""Stage HUD observers and derive the counted immutable original Main."""
from pathlib import Path
import hashlib,json,shutil,subprocess
root=Path.cwd()
if not (root/'project.godot').is_file():raise SystemExit('Run from the repository root.')
local=root/'.local';local.mkdir(exist_ok=True)
source=Path(__file__).resolve().parent
for name in ['hud_labels_focused.gd','hud_labels_legacy_parity.gd']:
    shutil.copyfile(source/name,local/name)
commit='700e304861c282bb11dcd762c0cae04a06ec2642'
path='game/main.gd'
data=subprocess.check_output(['git','show',commit+':'+path])
expected='f5d6b6980821993a09618ad95ca6bd62d2de6c8d1f9f683f12b29c6d784fc6aa'
if hashlib.sha256(data).hexdigest()!=expected:raise SystemExit('Original Main does not match inspected source.')
(local/'hud_label_original_main.gd').write_bytes(data)
original=data.decode()
counted=original.replace('Skater.TrickCatalog.definition(skater.grind_trick_id).get("display_name", "")','_counted_label(skater.grind_trick_id, "")').replace('Skater.TrickCatalog.definition(skater.manual_trick_id).get("display_name", "Manual")','_counted_label(skater.manual_trick_id, "Manual")')
counted+='\nvar label_reads := 0\nfunc _counted_label(id: String,fallback: String) -> String:\n\tlabel_reads+=1\n\treturn str(Skater.TrickCatalog.definition(id).get("display_name",fallback))\n'
if counted.count('_counted_label(')!=3:raise SystemExit('Unexpected original label-call sites.')
counted_bytes=counted.encode()
(local/'hud_label_original_counted_main.gd').write_bytes(counted_bytes)
(local/'hud-label-original-source.json').write_text(json.dumps({'git_commit':commit,'git_path':path,
    'original_sha256':expected,'counted_original_sha256':hashlib.sha256(counted_bytes).hexdigest(),
    'changes':'Only the two HUD label calls route through a read counter. Original Main code, constant imports, fallback values and refresh behavior otherwise remain unchanged.'},indent=2)+'\n')
print('Staged two HUD observers and the counted immutable original Main under .local.')
