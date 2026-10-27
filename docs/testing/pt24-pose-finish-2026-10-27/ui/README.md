# Controller menu controls and Back — 27 October 2026

C09's production HUD accepted the skating Pause binding for Back but omitted
the controller's Circle/B button. Nested pages therefore required Options or
Escape, or activating the visible Back control. The repair recognizes Circle/B
and `ui_cancel` only while a modal is open and binding capture is inactive,
then uses the existing navigation stack. Input setup also ensures native menu
bindings for Cross, Circle, the D-pad and the signed left stick, preserving
keyboard events and existing menu deadzones. On this engine only Cross/Circle
were missing; the existing D-pad/stick directions remain. Title/results retain
their existing no-resume policy. Capture still accepts Circle as a skating input.

Handled events also update polled gameplay actions. The cancel path releases
only skating actions matched by that same event before resuming, preventing
the modern trick engine from interpreting Back as a new Grab. Ordinary skating
keeps its existing actions; remapping preserves the initialized menu maps. No
geometry, render resource, persistence schema, career goal or Music request is
introduced. Menu registration occurs at setup; no per-frame system is added.

The focused fixture sends actual parsed Joypad button events and flushes the
engine's event buffer, following the existing classic-controller fixtures. It
uses ordinary Main with persistence disabled before tree entry; its airborne
case uses an actual charged Ollie and no actor transform/velocity/score writes.
It exercises nested settings/controls and map/goals, single-resume semantics,
title/results boundaries, capture, actual resumed trick state and a genuine
subsequent Circle-triggered Melon Grab. Root owns combined admission.

The installed headless engine reports `ui_cancel = [Escape]` and
`ui_accept = [Enter, Kp Enter, Space]`, with no built-in Joypad entries. The
repair therefore includes an explicit Circle predicate rather than assuming a
built-in controller mapping exists. These bounded synthetic event checks do not
certify physical wired/Bluetooth devices or Mac menu behaviour. The separate
controller-menu fixture tests actual D-pad/stick focus, Cross activation of
Career/Free skate and Resume, native slider adjustments and Cross capture.
Registration is idempotent and the existing InputProfile tests continue to
require remapping/reset to preserve the initialized menu bindings.

One limit is retained explicitly: `Input.action_release` does not erase Godot's
same-update `is_action_just_pressed` history. The older grab-request buffer can
therefore briefly report a request after menu cancellation even though the
modern trick engine has no held/pending/actual Grab and awards no trick. That
legacy request also participates in launch-family prediction; this repair does
not claim every legacy input edge or buffer is cleared. Its raw diagnostic is
preserved alongside the failed fixture assumptions.

The first rejected attempts assumed a controller mapping on `ui_cancel`, then
used a never-set legacy `_grab_used` field and required the old buffer to be
empty. The final assertions inspect actual trick ID/state and score entries;
the legacy buffer remains printed and disclosed rather than relabelled passed.
One explicit Circle candidate also failed parsing due to inferred Variant
typing; the final predicate declares `bool`. Raw failures and exact HUD/test
snapshots are retained. The first controller run also mistook the native spawn's
ordinary fall for an Ollie and assumed Settings began on a slider. The final
fixture allows35 ordinary native updates after a new run and navigates from
Soundtrack to the volume slider with a real D-pad press. No production change
was added to satisfy either assumption.

## Final focused and causal results

| Source/control | Result | Meaning |
| --- | --- | --- |
| [Admitted](focused/menu-controller-admitted/receipt.json) | **31/0**, exit0, clean/stable628 inputs,7.923s | All16 Back and15 native controller-menu assertions pass. |
| [Exact original HUD](focused/menu-controller-old-hud/receipt.json) | **23/8**, expected exit1, stable628 inputs | With current menu maps and identical tests, the old HUD still fails Circle Back navigation. |
| [Final HUD without action release](focused/menu-controller-no-release/receipt.json) | **29/2**, expected exit1, stable628 inputs | Circle Back adds a genuine Melon Grab on resume; the following Circle press tweaks it to Melon Grab Boned. This isolates why consuming the GUI event alone is insufficient. |

Final manifest SHA256:
`ca8782666bf09f454108e64051c69e97a68d888bf5454c035875cd3a3653a613`.
The control variants restore the final HUD byte-for-byte after their bounded
runs; they are retained diagnostics, not production sources or accepted results.

```sh
cp docs/testing/pt24-pose-finish-2026-10-27/ui/observers/menu_cancel_focused.gd .local/menu_cancel_focused.gd
python3 docs/testing/horizon-background/observers/run_checked.py .local/menu-controller-repeat timeout 45s ./tools/run.sh --headless --audio-driver Dummy --fixed-fps 60 --script .local/menu_cancel_focused.gd
```

All ten attempts retain their original receipts, source manifests and raw logs
under `focused/`. [Source snapshot index](source-snapshots.json) verifies20 exact
HUD/setup/test/observer blobs against those manifests, including the incorrect
initial fixtures and parser rejection. The registered production integration
suite runs both new modules; root owns required combined regression results.
Physical devices, reconnect behaviour on actual hardware, Mac execution and
human comfort remain open.
