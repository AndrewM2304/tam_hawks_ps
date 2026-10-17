# Tam Hawks Pro Skater — prototype player guide

Skate a Glasgow-inspired prototype, link tricks, and complete career goals during two-minute runs. The current build has an initial art and interface pass, local sound and voiced reactions. Further visual refinement, animation work and human playtesting remain part of the roadmap.

## Start

From source, open `project.godot` with free Godot 4.6.3 and press F5. A Linux standalone package contains `TamHawksProSkater.x86_64` and its adjacent `.pck`; extract both and run the executable. A macOS package contains `Tam Hawks Pro Skater.app`; it is an unsigned local test build, and actual Mac launch remains to be verified. If the OS refuses it, source play in the official editor remains available without buying signing or disabling security settings.

## Controls

| Action | Keyboard | Standard DualSense mapping to verify |
|---|---|---|
| Push / brake | W / S, or up / down | Left stick up / down |
| Steer | A / D, or left / right | Left stick left / right |
| Ollie | Space | Cross |
| Kickflip / grab | J / K | Square / Circle |
| Spin | Q / E | L1 / R1 |
| Grind | Hold L near a rail | Hold R2 |
| Manual | M | L2 |
| Revert after landing | C | Right-stick click |
| Special tricks | U / I | D-pad up / right |
| Interact near an object | X | D-pad down |
| Goals | Tab | Create / Back |
| Restart run | R | Triangle |
| Pause | Escape | Options |
| Switch career / free skate | F | Touchpad |

Gamepad names describe the intended standard mapping. Physical DualSense wired/Bluetooth behavior still needs a Mac playtest.

To change a binding, pause and open **Controls**, select an action, then press the desired key, gamepad button or axis. Escape cancels listening; **Reset defaults** restores the standard layout. Bindings are saved locally, and prompts follow the saved controls.

## Build a line

Push toward a ramp, ollie, then add a flip, grab or spin. Clean landing leaves a short 0.35-second link window: start another ollie, grind or manual to continue the combo; rolling normally lets it bank. A revert adds a trick without extending that window. A bail drops unbanked points. Repeating one trick reduces its value, while different tricks build the multiplier.

Hold grind while descending toward an aligned rail. Balance left/right against the meter's lean; ollie or leave the rail to carry your momentum onward. Manual on suitable ground and balance against the lean. Controls, tuning and landing forgiveness are still subject to human feel testing.

Banking points fills the special meter. A full meter powers one successful airborne special. Career goals unlock Clyde Carousel (bank 1,000 in a run) and Tenement Tumble (bank a 3,000-point combo). Free skate makes both available for practice but still requires charge; it does not complete career goals.

Open Goals to see the ten career tasks: scores, a long combo, H A W K S letters, cone duty, the Central gap, market items, four districts and a hidden recording. Goal completions, records, bindings and presentation settings use a local save; there is no account or online service. Pause/settings include sound mix, captions, reduced motion, interface size and camera sensitivity.

## Useful playtest notes

Record your computer/OS, keyboard or wired/Bluetooth controller, then note any sticking input, difficult rail capture, unclear balance direction, camera discomfort, unreadable text, missing sound, save failure or route that feels unrewarding. Include the package's `BUILD-METADATA.json` when reporting a defect. Automated Linux checks do not replace this controller and feel review.
