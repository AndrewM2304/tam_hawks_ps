Current arcade hardening: tap and release **Space/Cross** for a low, fast hop; hold about a quarter-second before releasing for the higher Ollie. The half-pipe automatically turns the rider back downhill; the turn itself earns no spin score. Hold **L/Triangle** on an approach to seek one rail catch, or tap just before contact; after locking, release stays on, another fresh tap drops, and release-Ollie pops. The latest source and validation limits are in STATUS.

# Tam Hawks Pro Skater — prototype player guide

Skate a Glasgow-inspired prototype, link tricks, and complete career goals during two-minute runs. Explore an original compressed Glasgow map with city terraces, fountain coping, station platforms, river crossings and hilly park paths, with local sound and voiced reactions. Further visual refinement, animation work and human playtesting remain part of the roadmap.

## Start

From source, open `project.godot` with free Godot 4.6.3 and press F5, or run `./tools/run.sh`. On Mac, use `GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" ./tools/run.sh`. The launcher prepares local assets before opening the game, including on a fresh download. A Linux standalone package contains `TamHawksProSkater.x86_64` and its adjacent `.pck`; extract both and run the executable. A macOS package contains `Tam Hawks Pro Skater.app`; it is an unsigned local test build, and actual Mac app launch remains to be verified. If the OS refuses it, source play in the official editor remains available without buying signing or disabling security settings.

## Controls

| Action | Keyboard | Standard DualSense mapping to verify |
|---|---|---|
| Push / brake | W / S, or up / down | Left stick up / down |
| Steer | A / D, or left / right | Left stick left / right |
| Crouch / ollie | Hold Space, release to pop | Hold Cross, release to pop |
| Flip / grab family | Direction + J / hold K | Direction + Square / hold Circle |
| Air spin | A/D or Q/E | Left stick or L1/R1 |
| Rail grind | Tap L; tap again to drop | Tap Triangle; tap again to drop |
| Manual / nose manual | Hold M; Up + M selects nose | Hold L2; Up + L2 selects nose |
| Revert after landing | C | R2 |
| Special tricks | U / I | D-pad up / right |
| Interact near an object | X | D-pad down |
| Goals | Tab | Create / Back |
| Restart run | R | Right-stick click (R3) |
| Pause | Escape | Options |
| Switch career / free skate | F | Touchpad |

Gamepad names describe the intended standard mapping. Physical DualSense wired/Bluetooth behavior still needs a Mac playtest.

To change a binding, pause and open **Controls**, select an action, then press the desired key, gamepad button or axis. Escape cancels listening; **Reset defaults** restores the standard layout. Bindings are saved locally, and prompts follow the saved controls. Existing custom layouts are retained; use Reset defaults to adopt Triangle grind, R2 revert and R3 restart. A conflicting old override reports a warning instead of replacing your controls silently.

Release Push to coast and slow naturally; hold Brake for a quicker stop. Ground steering now turns more tightly. In the air, left/right visibly spins the skater while preserving flight direction; Q/E or the shoulder buttons are alternate spin inputs. Camera sensitivity changes how quickly the view follows, so it does not change the skater's turning rate. The camera keeps a third-person view and moves to the side when a wall blocks the usual rear view.

Back returns to the menu you came from. Interaction prompts use your current keyboard or controller binding. Goal updates remain visible alongside an active combo.

## Graphics settings

Open **Settings** and select **Graphics** to cycle through the saved presets. Try Performance if play stutters; Balanced is the default.

| Preset | 3D render scale | View distance | Shadow distance | Anti-aliasing |
|---|---|---|---|---|
| Performance | 75% | 220m | 30m | Off |
| Balanced | Native | 220m | 45m | 2× MSAA |
| High | Native | 220m | 75m | 2× MSAA |

Menus and HUD stay at native resolution. Presets keep the same chase framing, field of view and controls; the connected map's collisions, tricks and challenges remain active. Performance reduces 3D resolution, anti-aliasing and shadow cost while retaining the same skyline range. See [performance testing](testing/PERFORMANCE.md) for measurement instructions and the limits of current evidence.

## Build a line

Push toward a ramp, ollie, then add a flip, grab or spin. Clean landing leaves a short 0.35-second link window: start another ollie, grind or manual to continue the combo; rolling normally lets it bank. A revert adds a trick without extending that window. A bail drops unbanked points. Repeating one trick reduces its value, while different tricks build the multiplier.

A flip/grab pressed just before takeoff, or a held manual pressed just before landing, has a short 120ms input margin. Tap grind while descending toward an aligned rail, or hold it through the approach for one catch. The rail stays locked after release; a second tap drops off. A released early tap has a short 140ms margin. Balance left/right against the meter's lean; hold/release Ollie to jump off, or tap Grind again to drop with your momentum. Hold manual on suitable ground and correct the fore/aft balance with push/brake (W/S or the stick up/down). Controls, tuning and landing forgiveness are still subject to human feel testing.

Choose the direction when pressing the trick button; changing direction afterward does not relabel that trick. Release a grab to let go. A held flip cannot repeat; a fresh press can start another flip after the first animation completes.

| Direction + family button | Flip (J / Square) | Held grab (K / Circle) |
|---|---|---|
| Neutral / left | Kickflip | Melon |
| Right | Heelflip | Indy |
| Up | Frontside Shuvit | Nose Grab |
| Down | Pop Shuvit | Tail Grab |
| Down-left | Varial Flip | Melon |
| Up-right | Hardflip | Indy |
| Up-left | Kickflip | Method |

Manuals also accept Up → neutral → Down, and nose manuals Down → neutral → Up, within 220ms. These gesture manuals stay latched while you balance; press the dedicated manual button to end one. A direct push-to-brake change does not count as that gesture. Nose manuals raise the rear truck and shift weight forward. Nollie/switch modifier combinations are not needed.

## Quarter-pipe, half-pipe and lips

Both features are on the **Clyde north quay**, near the existing Clyde checkpoint: a standalone quarter to the east and a half-pipe to the west, with the through-quay route left open. The half-pipe has open side access to its flat bottom. Push or hold Ollie to build speed; low speed rolls back naturally, higher speed reaches the vertical lip and returns under gravity. Ground turns, air spin and the camera keep separate jobs.

Hold Grind while approaching the top of a quarter-pipe to request a lip trick. Neutral selects **Axle Stall**, Up **Nose Stall**, Down **Tail Stall**, and Left/Right **Disaster**. Balance left/right, release Grind to drop back into the ramp, or hold/release Ollie to pop out. Lip holds are bounded and ordinary career overtime still ends after three seconds. A wall, flat ground or the back of a ramp cannot create a lip trick.

Banking points fills the special meter. A full meter powers one successful airborne special. Career goals unlock Clyde Carousel (bank 1,000 in a run) and Tenement Tumble (bank a 3,000-point combo). Free skate makes both available for practice but still requires charge; it does not complete career goals.

Open Goals to see the ten career tasks: scores, a long combo, H A W K S letters, cone duty, the Central gap, market items, four districts and a hidden recording. Goal completions, records, bindings and presentation settings use a local save; there is no account or online service. Pause/settings include sound mix, captions, reduced motion, interface size and camera sensitivity.

If a save cannot be loaded or written, a persistent warning explains that progress is staying in the current session. You can keep playing; existing unreadable or newer saves are protected.

## Explore Glasgow

Open **City map & routes** from Pause or Goals. The arrow shows your position and heading; brighter routes climb higher and orange lines mark jump routes. Looking at the map pauses your run.

Your start faces a clear uphill line beside the fountain. Climb the gallery banks into George Square, choose the station's raised platforms, or head east through the Barras loading streets. The fountain rim is a curved grind: approach along its tangent, ollie and hold grind as you descend.

Head south to the Clyde quays for embankment lines and a broken-footbridge transfer. Build speed and ollie the opening; a continuous bridge provides another way across. Falling into the river returns you to a safe quay and loses your pending combo. Restart still returns you to the original city start.

Northwest, follow the park connections to a winding paved climb and downhill run through rolling grass. The map compresses Glasgow into connected skating places; it is an original game layout rather than a street navigation map.

The ten career goals remain in the four city districts. River and park routes are open in both modes; **Free skate** gives you unlimited time to learn them.

## Glasgow side challenges

Find Mo, the guitarist at the east edge of the Exchange fountain court, and use the displayed interaction key to accept **Mo's Big Finish**. Start with a settled combo, then bank at least 1,000 points using three different trick types in one clean line within 35 seconds. An ollie, flip and grab is a good first attempt; spins, grinds and manuals offer other approaches. Stay in the court. The timer and type count remain visible while you skate.

A bail or timeout ends the attempt. Return to Mo to replay. The challenge is available in career and free skate and keeps its own session result alongside the ten career goals. Music follows the master and ambience sliders.

Find Rae’s **bin drums and two soft dancing cats** at **George Square’s garden busking pitch** for **Cat’s Got the Beat**. Accept the offer with a settled combo, then grind the three marked coping segments **A → B → C** within 60 seconds. The approach runs east along the garden’s south edge; use the wide square to return and line up again. Each segment must be a real grind capture. You can bank separate lines between segments. After the third, land and bank cleanly, then return to Rae and look toward the drums to see the cats’ little dance.

Repeating the most recent segment adds no progress. A wrong marked segment resets the sequence; starting again on A begins a fresh sequence. A bail, timeout or leaving the busking area ends the attempt. The steady world indicators and HUD show the next segment. Reduced motion uses static raised paws. Return to Rae to replay. The original spatial techno-percussion loop follows Master and Ambience volume, pauses with the game and stops at run end.

Only one side challenge is active at a time: accepting another offer ends the previous attempt. Career time reaching zero ends side attempts even if an ordinary combo still has overtime to land. Side completion adds no extra career goal, points or unlock; normal skating scores as usual. Free skate gives unlimited run time for practising either encounter.

New route choices include the low station undercroft beneath the high platform route, Merchant Close's angled passage, a second park descent back toward Central, and the Clyde print-yard loop with a low curved bank and hip. Use the map to find the branches and try both directions.

## Useful playtest notes

Record your computer/OS, keyboard or wired/Bluetooth controller, then note any sticking input, difficult rail capture, unclear balance direction, camera discomfort, unreadable text, missing sound, save failure or route that feels unrewarding. Include the package's `BUILD-METADATA.json` when reporting a defect. Automated Linux checks do not replace this controller and feel review.


### Gull-Proof Delivery — through the Barras

Find Mairi's breakfast-parcel stall on the loading terrace below the Barrowland sign. Settle your current combo, then interact to collect the courier bag and start the 60-second delivery. Manual toward the loading steps, ollie the marked **Market Loading Steps** gap and land a clean bank in the same line. Banking too early lets you retry while the clock keeps running.

After the jump, choose the **Covered market** or **Calton lane** entrance, pass its three numbered markers in order and reach the **south delivery counter**. The first marker commits your lane. Steady world markers highlight the next target; the HUD gives its direction and distance. The first entrance is behind the fast stair landing, so follow the turn-back cue to hook into the market. A bail, leaving the market or timeout returns the parcel to Mairi. On success, your breakfast is safe and the gull raids a spare wrapper. Look toward the counter for the short response; reduced motion uses a static pose. Return to Mairi to replay. This optional challenge works in either mode and does not add a saved career goal.

### Exchange/gallery skating edges

The gallery entrance has low side banks leading to a raised stone terrace and an angled seating ledge. Use a controlled approach: full speed carries the bank's extra lift past this short ledge. Ollie onto it with Grind held, then ollie off and start a Manual after landing to continue the line. The open apron leads back toward the existing gallery stairs and fountain. These are ordinary skating opportunities; there is no extra challenge offer or saved goal.

The west shopfronts have a separate low seating edge and bank. Ride up and back down, or try its coping, while the broad street beside it remains available for an easier pass. The city map shows the authored local routes. Both attachments are original game layouts informed by Glasgow architecture.
