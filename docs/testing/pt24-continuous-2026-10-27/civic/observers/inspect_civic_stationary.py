"""Read native same-camera pixels; never classify moving parallax as flicker."""
from pathlib import Path
import hashlib, json, sys
import numpy as np
from PIL import Image

root = Path(sys.argv[1] if len(sys.argv) > 1 else '.local/civic-shadow-witness/normal')
manifest = json.loads((root / 'manifest.json').read_text())
assert manifest['source_stable'] and manifest['source_before'] == manifest['source_after']
results = []
for record in manifest['records']:
    if record['phase'] != 'stationary':
        continue
    rows = record['rows']
    assert len(rows) == 6 and all(row['camera'] == rows[0]['camera'] for row in rows)
    assert all(b['process_frame'] > a['process_frame'] for a, b in zip(rows, rows[1:]))
    frames = []
    for row in rows:
        path = root / row['image']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == row['image_sha256']
        frames.append(np.asarray(Image.open(path).convert('RGB'), dtype=np.int16))
    pairs = []
    for number, (a, b) in enumerate(zip(frames, frames[1:])):
        absolute = np.abs(a-b)
        difference = np.max(absolute, axis=2)
        any_y, any_x = np.where(difference > 0)
        yy, xx = np.where(difference > 2)
        pairs.append({'from': number, 'to': number+1,
                      'max_rgb_change': int(difference.max()),
                      'max_absolute_channel_deltas': absolute.max(axis=(0, 1)).tolist(),
                      'mean_absolute_channel_deltas': absolute.mean(axis=(0, 1)).tolist(),
                      'changed_pixels': {str(t): int(np.count_nonzero(difference > t)) for t in [0, 2, 8]},
                      'bounds_any_change': [int(any_x.min()), int(any_y.min()), int(any_x.max()), int(any_y.max())] if len(any_x) else None,
                      'bounds_over_2': [int(xx.min()), int(yy.min()), int(xx.max()), int(yy.max())] if len(xx) else None})
    results.append({'witness': record['witness'], 'native_frames': len(frames),
                    'identical_stationary_cameras': True, 'consecutive_pairs': pairs})
print(json.dumps({'method': 'Read-only consecutive native stationary frames, SHA-verified and identical camera. RGB pixel differences locate changes; they do not establish their cause or Mac temporal acceptance.', 'results': results}, indent=2))
