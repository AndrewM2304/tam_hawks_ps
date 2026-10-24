# Trick-fidelity source-launch receipt

Final verification: **23 October 2026, 22:56:46–22:58:33 UTC**. Command:

```sh
python3 tools/source_launch_smoke.py --output .local/trick-fidelity-cold-verified
```

The disposable source copy starts without `.godot`. Cold import/ordinary Main,
normal title-to-free-skate (**44 passed / 0 failed**), warm launch and deliberate
syntax-error refusal all pass. The injected error exists only in the copy and is
restored. Production source and the restored copy remain unchanged across all
four phases; **186 source inputs** are recorded.

- [Machine receipt](SOURCE-LAUNCH.json): SHA-256
  `113dabd42ec413522810f3c3706ba83cba2a3ff83142dbe9d9504ac9813e1eec`.
- Source fingerprint:
  `697649ddbcb6bc122900b27c558d9adc3dc44380d4f284b5ad5cf7487e20c16e`.
- [Cold log](cold.log), [normal title branch](normal-branch.log),
  [warm log](warm.log), [expected broken-copy refusal](invalid-source.log).

The launcher's `SOURCE-LAUNCH` receipt and per-phase import logs are preserved
beside this file. Paths to the disposable project describe its original `.local`
execution; the copied project/cache is intentionally not committed. Headless
Linux/Dummy-audio results do not certify native Mac launch, listening or frame rate.
