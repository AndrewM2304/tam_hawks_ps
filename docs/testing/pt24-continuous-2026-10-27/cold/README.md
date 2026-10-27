# Current source launch — 27 October 2026

`python3 tools/source_launch_smoke.py --output .local/pt24-continuous-cold-next`
passes all four phases on **559 unchanged inputs**. The disposable copy starts
without `.godot`; cold import, the normal title→play branch **50/0**, warm launch
and deliberate invalid-copy refusal all pass. The injected parse failure exists
only in that copy, is refused before launch and is restored afterward.

[Raw receipt](SOURCE-LAUNCH.json) retains fingerprint
`ed3c8c75c56158a46594d18feda439fcd00b959bad5fe5eec447cbedf44c338b`, exact
input hashes and each phase log. The original checkout remains unchanged. These
headless Linux phases do not execute a Mac binary or certify target performance.
