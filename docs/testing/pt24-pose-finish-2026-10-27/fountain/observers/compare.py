"""Report the existing water-control caps without pooling failed views."""
from pathlib import Path
import json, math, sys

source = Path(sys.argv[1])
result = json.loads(source.read_text())

def percentile(values, quantile):
    rows = sorted(values)
    return rows[max(0, math.ceil(len(rows) * quantile) - 1)]

def summary(rows):
    values = [row['ms'] for row in rows]
    return {
        'samples': len(rows), 'p50_ms': percentile(values, .50),
        'p95_ms': percentile(values, .95), 'p99_ms': percentile(values, .99),
        'max_ms': max(values),
        'over_16_667_ms': sum(t > 1000 / 60 for t in values),
        'over_33_333_ms': sum(t > 1000 / 30 for t in values),
        'over_50_ms': sum(t > 50 for t in values),
        **{field: {'min': min(row[field] for row in rows), 'max': max(row[field] for row in rows)}
           for field in ('draws', 'primitives', 'objects', 'total_draws', 'total_primitives', 'texture_bytes', 'buffer_bytes', 'video_bytes')},
    }

comparisons = []
for view in ('overhead', 'low-rim'):
    phases = {row['phase']: row for row in result['views'] if row['view'] == view}
    summaries = {phase: summary(value['rows']) for phase, value in phases.items()}
    counters_equal = all(
        original[field] == candidate[field] == repeated[field]
        for original, candidate, repeated in zip(phases['original-a']['rows'], phases['shared-water']['rows'], phases['original-b']['rows'])
        for field in ('draws', 'primitives', 'objects', 'total_draws', 'total_primitives', 'texture_bytes', 'buffer_bytes', 'video_bytes'))
    gates = {}
    for key in ('p95_ms', 'p99_ms'):
        first, candidate, last = (summaries[p][key] for p in ('original-a', 'shared-water', 'original-b'))
        midpoint = (first + last) / 2
        spread_cap = midpoint + abs(first - last) + .05 * midpoint
        worse_control_cap = 1.05 * max(first, last)
        gates[key] = {'candidate_ms': candidate, 'spread_cap_ms': spread_cap,
                      'worse_control_cap_ms': worse_control_cap,
                      'passes': candidate <= min(spread_cap, worse_control_cap)}
    comparisons.append({'view': view, 'phases': summaries, 'all_sample_counters_equal': counters_equal,
                        'timing_gates': gates, 'timing_passes': all(g['passes'] for g in gates.values())})

out = {'source_manifest': str(source), 'method': 'Nearest-rank percentiles of retained native frame_post_draw wall-clock intervals. Existing water-control diagnostic p95 and p99 caps apply independently per view: control midpoint + absolute repeat difference +5% midpoint AND 1.05 times worse control. Counters compare every matching camera sample. These short Linux software-rendered sweeps cannot certify target-Mac motion/performance or final water art.',
       'views': comparisons,
       'counter_gate_passes': all(view['all_sample_counters_equal'] for view in comparisons),
       'timing_gate_passes': all(view['timing_passes'] for view in comparisons)}
target = source.with_name('comparison.json')
target.write_text(json.dumps(out, indent=2) + '\n')
print(json.dumps(out, indent=2))
raise SystemExit(0 if out['counter_gate_passes'] and out['timing_gate_passes'] else 1)
