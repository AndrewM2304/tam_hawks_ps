# Current full-fidelity cold-source launch

`python3 tools/source_launch_smoke.py --output .local/full-fidelity-cold-final`
passes with **260 unchanged inputs**, disabled profile writes and isolated copies.
The cold import/start, actual normal Main/title **44/0**, warm launch, deliberate
broken-copy refusal and source-byte restoration pass. The intentionally invalid
copy exits1; that refusal is expected. Other engine phases exit0 with clean logs.

[SOURCE-LAUNCH.json](SOURCE-LAUNCH.json) contains every input hash, phase command,
limits and result. Its SHA-256 is
`0c522cf86588b614a28c32c71bab2624b1890c8206a233176f590d5a744b96c6`.
The exact source fingerprint is
`ad60d68afa696b4920a293219cb2941e981af3222ec6c37cd504c56563920d57`.
The original checkout and copied source both remain unchanged after the check.

This is Linux/headless source preparation and synthetic mapped-input verification,
not a Mac launch, rendering-performance or physical controller acceptance result.
Current full regression/motion/package receipts are recorded separately in STATUS.
