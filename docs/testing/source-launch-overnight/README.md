# Current-source cold startup verification

`python3 tools/source_launch_smoke.py --output .local/overnight-cold-complete`
completed with exit 0. A cache-free copy imported and launched, the unmodified
Main/title branch passed 44/0, a warm launch passed, and a deliberately broken
copy was refused (expected exit 1), restored and checked. No original source was
modified: all 210 input identities stayed unchanged. The exact commands, phase
exit codes and file hashes are in [SOURCE-LAUNCH.json](SOURCE-LAUNCH.json).

Receipt SHA-256: `58f92b52e282d10208e0fa8437f1f5f1cb0d45cc80ca5e2ff1cc041400a0d8e8`.

The separate log files preserve actual import/launch results. Error text in the
invalid-source phase is deliberate refusal evidence, not an original-checkout
failure. This is Linux/headless startup evidence; no native Mac app or physical
controller was tested. No export or spending was involved.
