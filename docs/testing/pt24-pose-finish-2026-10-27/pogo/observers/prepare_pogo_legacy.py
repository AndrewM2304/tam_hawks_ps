"""Prepare an immutable pre-fix visual and isolated preload-only controls."""
from pathlib import Path
import hashlib
import json
import subprocess

root = Path.cwd()
revision = 'b257b5682bdd40310660cc4be8b40ba20717ee7f'
original_path = 'game/player/skater_visual.gd'
original = subprocess.check_output(['git', 'show', f'{revision}:{original_path}'])
expected = 'f0e3f3287dacff041cdf3b82a6f7ce8629025472822870ee923c470f9d0dbde7'
assert hashlib.sha256(original).hexdigest() == expected
local = root / '.local'
local.mkdir(exist_ok=True)
(local / 'pogo_attachment_legacy_visual.gd').write_bytes(original)
records = [{'source_revision': revision, 'source': original_path,
            'target': '.local/pogo_attachment_legacy_visual.gd', 'sha256': expected,
            'transformation': 'None; immutable committed source bytes.'}]
for source_path, target_name, replacements in [
    ('game/player/skater.gd', 'pogo_attachment_legacy_skater.gd', [
        ('res://game/player/skater_visual.gd', 'res://.local/pogo_attachment_legacy_visual.gd')]),
    ('tests/authentic_pose_tests.gd', 'pogo_attachment_legacy_authentic.gd', [
        ('res://game/player/skater_visual.gd', 'res://.local/pogo_attachment_legacy_visual.gd')]),
    ('tests/classic_tricks_integration_tests.gd', 'pogo_attachment_legacy_classic.gd', [
        ('res://game/player/skater.gd', 'res://.local/pogo_attachment_legacy_skater.gd')]),
    ('tests/skater_pogo_attachment_tests.gd', 'pogo_attachment_legacy_tests.gd', [
        ('res://tests/authentic_pose_tests.gd', 'res://.local/pogo_attachment_legacy_authentic.gd'),
        ('res://tests/classic_tricks_integration_tests.gd', 'res://.local/pogo_attachment_legacy_classic.gd')]),
]:
    source = (root / source_path).read_bytes()
    transformed = source.decode()
    for old, new in replacements:
        assert transformed.count(old) == 1, (source_path, old)
        transformed = transformed.replace(old, new)
    target = local / target_name
    target.write_text(transformed)
    records.append({'source': source_path, 'source_sha256': hashlib.sha256(source).hexdigest(),
                    'target': str(target.relative_to(root)), 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                    'transformation': [{'old': old, 'new': new} for old, new in replacements]})
(local / 'pogo-legacy-sources.json').write_text(json.dumps(records, indent=2) + '\n')
print(json.dumps(records, indent=2))
