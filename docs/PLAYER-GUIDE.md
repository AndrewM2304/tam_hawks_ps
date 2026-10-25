Current arcade hardening: tap and release **Space/Cross** for a low, fast hop; hold about a quarter-second before releasing for the higher Ollie. The half-pipe automatically turns the rider back downhill; the turn itself earns no spin score. Hold **L/Triangle** on an approach to seek one rail catch, or tap just before contact; after locking, release stays on, another fresh tap drops, and release-Ollie pops. The latest source and validation limits are in STATUS.

# Tam Hawks Pro Skater — prototype player guide

Skate a Glasgow-inspired prototype, link tricks, and complete career goals during two-minute runs. Explore an original compressed Glasgow map with city terraces, fountain coping, station platforms, river crossings and hilly park paths, with local sound and voiced reactions. Further visual refinement, animation work and human playtesting remain part of the roadmap.

## Start

From source, open `project.godot` with free Godot 4.6.3 and press F5, or run `./tools/run.sh`. On Mac, use `GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" ./tools/run.sh`. The launcher prepares local assets before opening the game, including on a fresh download. A Linux standalone package contains `TamHawksProSkater.x86_64` and its adjacent `.pck`; extract both and run the executable. A macOS package contains `Tam Hawks Pro Skater.app`; it is an unsigned local test build, and actual Mac app launch remains to be verified. If the OS refuses it, source play in the official editor remains available without buying signing or disabling security settings.

## Controls

| Action | Keyboard | Standard DualSense mapping to verify |
|---|---|---|
| Push / brake | W / S, or up / down | D-pad or left stick up / down |
| Steer | A / D, or left / right | D-pad or left stick left / right |
| Crouch / ollie | Hold Space, release to pop | Hold Cross, release to pop |
| Flip / grab family | Direction + J / hold K | Direction + Square / hold Circle |
| Air spin | A/D or Q/E | Left stick or L1/R1 |
| Rail grind | Tap L; tap again to drop | Tap Triangle; tap again to drop |
| Manual / nose manual | Up–Down manual / Down–Up nose; M shortcut | D-pad or stick Up–Down / Down–Up; L2 shortcut |
| Revert after landing | C | R2 |
| Special tricks | U / I | Right stick up / down |
| Interact near an object | X | L3 |
| Goals | Tab | Create / Back |
| Restart run | R | Right-stick click (R3) |
| Pause | Escape | Options |
| Switch career / free skate | F | Touchpad |

Gamepad names describe the intended standard mapping. Physical DualSense wired/Bluetooth behavior still needs a Mac playtest.

To change a binding, pause and open **Controls**, select an action, then press the desired key, gamepad button or axis. Escape cancels listening; **Reset defaults** restores the standard layout. Bindings are saved locally, and prompts follow the saved controls. Existing custom layouts are retained; use Reset defaults to adopt the directional D-pad, right-stick specials, L3 interaction and current face-button layout. A conflicting old override reports a warning instead of replacing your controls silently.

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

Hold Ollie to crouch and release it to pop. A short tap gives the normal jump;
holding longer adds height. A hold of about 0.25 seconds reaches full charge.
Watch the charge percentage. While preparing, make a fresh forward direction tap just
before release for **Nollie**, back for **Boneless**, or back while holding Manual
for **No Comply**. That direction must be fresh within 0.18 seconds of release;
holding Push throughout the approach keeps an ordinary Ollie.

Boneless and No Comply need real ground beside the board. Boneless plants a
foot and grips the deck during a 0.22-second preparation; No Comply uses a
0.16-second footplant before its pop. Preparation slows the approach, so leave
room for it. Missing or interrupted foot support cannot award either move.
These grounded setups are not selected from a rail, wallride or curved-transition
state. Both feet return to the board during the airborne catch.

Push toward a ramp, pop, then add a flip, grab or spin. Clean landing leaves a
short 0.35-second link window: release another prepared Ollie, catch a grind or
start a manual to continue the combo. Wallrides and lip stalls also keep an
existing line alive. Rolling normally, including carving a supported transition,
lets it bank. A revert adds a trick without extending that window. A bail drops
unbanked points and special charge; banked score survives. The rider falls,
slides or rolls, then gets up on supported ground. Unsafe falls use a faded safe
return; holding a button through recovery does not create another fresh pop.
Pause freezes recovery too. At the end of a timed
run an existing combo gets at most three seconds to resolve.

Every accepted trick entry raises the multiplier, including repeats, up to 100.
Repeating a move halves its base value down to a sixteenth. That staleness lasts
through banks and bails for the whole run; Restart restores fresh values. Held
grabs/grinds and rotation add points without adding multiplier entries.

Open **Trick Guide** from Pause or Controls for the full set and live bindings.
Ordinary directional buttons preserve the familiar controls:

| Direction + family | Flip | Held grab |
|---|---|---|
| Neutral / left | Kickflip | Melon Grab |
| Right | Heelflip | Indy Grab |
| Up | Frontside Shuvit | Nose Grab |
| Down | Pop Shuvit | Tail Grab |
| Down-left | Varial Flip | Melon Grab |
| Up-right | Hardflip | Indy Grab |
| Up-left | Kickflip | Method Grab |

For the **advanced air set**, tap the same direction twice with a genuine neutral
release between taps, then press Flip or Grab on the second tap. Complete the
sequence within 0.30 seconds. This uses your existing directions and buttons;
a single held direction keeps its ordinary selection. While grinding, the same
directions with a fresh Flip or Grab select the rail styles below.

| Advanced direction | Flip | Grab | Rail style change |
|---|---|---|---|
| Neutral | Kickflip | Melon Grab | Rail Grind |
| Up | Hardflip | Nose Grab | Nosegrind |
| Down | Pop Shove-it | Tail Grab | 5-0 Grind |
| Left | Kickflip | Melon Grab | Lipslide |
| Right | Heelflip | Indy Grab | Boardslide |
| Up-left | Varial Kickflip | Mute Grab | Crooked Grind |
| Up-right | Inward Heelflip | Japan Grab | Overcrook Grind |
| Down-left | 360 Flip | Method Grab | Smith Grind |
| Down-right | Varial Heelflip | Stalefish Grab | Feeble Grind |

Release Flip, let the board catch, then press again to add another flip in the
same jump. Every directional flip has a quick second- and third-tap upgrade:
double/triple kickflips, heelflips, hardflips, varial flips, inward heelflips and
360 Flips; Pop Shove-it upgrades to **360 Shove-it**, then **540 Shove-it**.
Each next tap must be within 0.22 seconds while the current move is unfinished.
The upgrade keeps one multiplier entry and continues the board's rotation;
leave extra airtime to finish the catch. A press shortly before the
current catch can queue the next action for up to 0.18 seconds. Press Flip and
Grab together to queue the grab after the flip. Hold Grab to keep the pose and
release it to let go; sustained grabs and grinds each have a 300-point hold cap.
Late unfinished flips and specials can bail on landing.

Double-tap Grab during an active grab to tweak it once: forward or neutral gives
**Boned**, back **Tucked**, right **Twisted**, and left **Extended**. The hand keeps
its deck contact while the body and legs change pose. The tweak adds 150 base
points before repetition adjustment and upgrades the same entry.

Use Spin to complete half or full turns. A half-turn changes the board's facing
and functional stance while momentum carries on; a sideways landing more than
45 degrees from a completed half-turn bails. The HUD distinguishes **Regular**,
**Switch** and **Fakie**, and air-trick receipts can show Switch, Fakie or Nollie
takeoff. Rotation appears beside the air trick and adds points without another
multiplier entry. A revert also changes facing and costs some speed.

For an easier landing link, press and hold Manual just before touching down
(within 0.18 seconds). Holding it from the start of a jump will not enter a manual.
A deliberate fresh up direction plus Manual selects Nose Manual; ordinary held
pushing alone keeps the usual manual. A quick forward → back gesture also starts
Manual, while back → forward starts Nose Manual; make the two direction changes
within 220 ms, including a genuine neutral release between them. Gesture manuals stay latched until you press Manual again,
pop, lose support or run out of speed. While balancing, use these style changes:

| Direction with the button | Flip | Grab | Revert |
|---|---|---|---|
| Neutral | One-foot Manual | Spacewalk | Manual Pivot |
| Forward | One-foot Nose Manual | Hang Ten | Nose Manual Pivot |
| Back | Casper Manual | Pogo | Manual Pivot |
| Left or right | Crossfoot Manual | Crossfoot Manual | Manual Pivot |

Diagonals use their forward/back component for these extensions. A changed style
adds one entry after a 0.35-second cooldown while the existing balance continues.
Pivots turn the physical facing and cost speed. The balance card names the ride.

Tap Grind while descending toward an aligned rail, or hold it through the approach
for one catch. A released early tap has a 140 ms margin. On verified contact rails,
neutral/up/down selects **50-50**; left/right chooses a signed **Boardslide**.
The rail remains locked after release. Balance left/right against the meter's lean. While grinding, choose a direction and tap
Flip or Grab to change style. Hold and release Ollie to pop off; steering during
release adds an outward pop while keeping the rail's momentum. Tap Grind again to
leave the rail. Press Revert while grinding for **Grind Pivot**: turn the facing
180 degrees, retain travel along the rail and spend 15 percent of its speed.
Manuals need suitable ground and some rolling speed; correct
balance with Left/Right (A/D, D-pad or left stick). Correction does not turn the
board: Q/E or L1/R1 steer during a manual. Controls and landing forgiveness still need
human feel testing.

Accepted trick, rotation and hold points fill the special meter while you skate.
Full charge activates **Special**. Its charge drains over six seconds, or twelve
while a combo continues without further awards; more tricks refresh it. A special
does not empty the meter, so another can follow when its animation finishes and
airtime permits. Partial charge fades after a short idle grace. Pause freezes
charge, and a bail or Restart clears it.

With Special active and enough airtime, enter either direction sequence and its
final face button within 0.45 seconds. Finish the current flip or grab first.

| Original special | Direction sequence + button | Default keyboard |
|---|---|---|
| Clyde Carousel | Left → right + Flip | A → D + J; U also works |
| Tenement Tumble | Forward → back + Grab | W → S + K; I also works |
| Kelvin Corkscrew | Right → left + Flip | D → A + J |
| Barras Butterflip | Back → forward + Grab | S → W + K |
| Bridge Blender | Forward → right + Flip | W → D + J |
| Sandstone Salute | Back → left + Grab | S → A + K |

Banking 1,000 in a career run unlocks the Carousel family: Clyde Carousel, Barras
Butterflip and Bridge Blender. A 3,000-point combo unlocks Tenement Tumble,
Kelvin Corkscrew and Sandstone Salute. Free skate makes all six available for
practice but still requires charge; it does not complete career goals.

The catalog contains **78 authored definitions**, with existing default trick IDs
retained as live compatible names. Its directory includes 24 flips, eight
grabs, ten grind entries, eleven manuals, nine lip tricks and six original
specials, plus launches, Wallride, Skitch, rotation, Revert and named gaps.
This is an implemented prototype repertoire; controller feel, animation quality
and commercial-game fidelity still need human review.

Open Goals to see the ten career tasks: scores, a long combo, H A W K S letters, cone duty, the Central gap, market items, four districts and a hidden recording. Goal completions, records, bindings and presentation settings use a local save; there is no account or online service. Pause/settings include sound mix, captions, reduced motion, interface size and camera sensitivity.

If a save cannot be loaded or written, a persistent warning explains that progress is staying in the current session. You can keep playing; existing unreadable or newer saves are protected.

## Your Apple Music soundtrack (Mac)

The default soundtrack is your supplied [Tony Hawk Pro Skater playlist by Alex Troyan](https://music.apple.com/gb/playlist/tony-hawk-pro-skater/pl.u-jV89Dq9t27eY8). Open **Soundtrack** from the title, Settings or Pause, then **Open default playlist in Music**. Sign into Music and add this playlist to its library once. Subscription songs require an active Apple Music subscription; adding the songs to the library too gives the best track-information/artwork support.

Choose **Connect to Music** and allow macOS to control Music. The game selects the saved **Tony Hawk Pro Skater** playlist automatically when its name is unique. If you have several with that name, choose the correct one in the picker. Refresh after adding it. Automatic shuffled playback is enabled by default for this personal soundtrack and starts when you enter a skating session; you can turn it off or select another playlist. **Shuffle & play** also starts it immediately. Music continues through Pause and Restart. Pause shows the current song, artist, album and available artwork, with play/pause and skip controls.

This controls your existing Music session. Set soundtrack volume in Music; the game sound sliders control skating effects and ambience. Disconnect turns off the integration/autoplay without stopping Music. If access is denied, allow it under **System Settings → Privacy & Security → Automation** for the app hosting the game, then reconnect. Source play may identify Godot or Terminal as that app.

Artwork or track information may be unavailable for some streams; the menu then uses fallback artwork. The feature is Mac-only and optional. Playback, shuffle and the permission prompt still need target-Mac testing; the Linux development checks use fixtures.

## Explore Glasgow

Open **City map & routes** from Pause or Goals. The arrow shows your position and heading; brighter routes climb higher and orange lines mark jump routes. Looking at the map pauses your run.

Your start faces a clear uphill line beside the fountain. Climb the gallery banks into George Square, choose the station's raised platforms, or head east through the Barras loading streets. The fountain rim is a curved grind: approach along its tangent, ollie and hold grind as you descend.

Head south to the Clyde quays for embankment lines and a broken-footbridge transfer. Build speed and ollie the opening; a continuous bridge provides another way across. Falling into the river returns you to a safe quay and loses your pending combo. Restart still returns you to the original city start.

Northwest, follow the park connections to a winding paved climb and downhill run through rolling grass. The map compresses Glasgow into connected skating places; it is an original game layout rather than a street navigation map.

At the top of the climb, follow the signed summit link west to **Kelvingrove
Sunken Skatepark**. Its diamond on **City map & routes** marks the east entrance,
within the existing park district. The gentle east bank rolls down into the lower
street basin; use it to enter and leave without a required jump. Start with the
shallow bowl and open runouts, then build speed for the deeper bowl and hip.
The stair set, hubba, flatbar and low ledge offer linked street lines around the
bowls. Coping uses the same Grind, lip, balance and transfer controls as other
transitions. The original park paths and lap routes remain available; Restart
still returns you to the city start.

The west Clyde quay and Kelvingrove promenade now have practice pockets with
curved quarter-pipes, low ledges and manual pads; the quay also has a flatbar.
Carry speed up a quarter-pipe for vertical air and descend back onto its curved
face. Too little speed rolls back down. Hold Grind as you reach the coping for
**Lip Stall**, balance left/right, then release Grind to drop in or release a
prepared Ollie to launch away. Each quarter-pipe has a side roll-in and deck. For a transfer in vert air,
release the approach direction and tap Push again to cross the deck, or tap Brake
to move back out over the ramp. A held approach Push keeps the normal vertical
return. Left/right adjusts lateral travel; the transfer adds no upward boost.
Use clear approaches and leave room around the finite sides.

Central now also has a connected halfpipe by the concourse and a narrow spine
farther west. Carry speed across the halfpipe's flat bottom to reach its opposite
wall; use a deliberate deckward transfer to cross the spine. On the east Clyde
quay, the bowl has a flat bottom, continuous curved wall, coping and a roll-in.
Steer around its wall to carve a continuing line. These authored surfaces share
the transition controls above; momentum and actual contact determine the return.

At a coping, make a fresh direction tap as you hold Grind to select the lip
style. Balance left/right while holding it:

| Direction | Lip trick |
|---|---|
| Neutral | Lip Stall |
| Forward / back | Nose Stall / Tail Stall |
| Right / left | Axle Stall / Rock and Roll |
| Forward + right / forward + left | Handplant / Invert |
| Back + right / back + left | Eggplant / Disaster Stall |

While stalled, direction + Flip or Grab changes to the corresponding style.
Without a direction, Flip selects Handplant, Grab selects Invert and Revert
pivots into Rock and Roll. The palm-supported poses place the hand or hands on
the coping. Release Grind to drop in, or release a prepared Ollie to pop away.

Beside a substantial solid vertical wall, approach at a glancing angle in the
air and hold Grind to **Wallride**. Hold and release Ollie for a **Wallie** away
from it, or release Grind to drop off. Rides lose momentum and have a short time
limit. Glass, water, open fences, thin furniture and the map's safety boundary
are excluded. Exposed collision-backed seating, planter edges, coping and practice
ledges have grind paths; stocked counters, overhead shelters and scenery beyond
the boundary remain scenery. Surface eligibility still depends on your approach,
clearance and speed, so the inventory does not promise every angle is capturable.
The [surface audit](levels/FULL-FIDELITY-LEVEL-AUDIT.md) records the current wall,
ledge and clearance evidence and the deliberate exclusions.

The ten career goals remain in the four city districts. River and park routes are open in both modes; **Free skate** gives you unlimited time to learn them.

The **Quay Crew** electric service cart runs along the west Clyde quay, stopping
before obstacles and waiting at each end. Roll behind it in the same direction,
hold Grind and press Interact to catch its rear bar. The hands only grip once the
native catch reaches the handle. Balance left/right during the tow; release
Grind to let go or hold/release Ollie to jump off with its momentum. A tow lasts
at most six seconds and ends if the cart stops or support is lost. Its bed and
cab roof also act as moving ground: land on them to ride, then ollie off. This is
one optional service cart, not a city traffic simulation.

## Glasgow side challenges and local features

Only one side challenge is active at a time: accepting another offer ends the previous attempt. This includes the river cone stunt and park lap below. Career time reaching zero ends side attempts even if an ordinary combo still has overtime to land. Side completion adds no extra career goal, points or unlock; normal skating scores as usual. Free skate gives unlimited run time for practising these activities.

### Mo's Big Finish

Find Mo, the guitarist at the east edge of the Exchange fountain court, and use the displayed interaction key to accept **Mo's Big Finish**. Start with a settled combo, then bank at least 1,000 points using three different trick types in one clean line within 35 seconds. An ollie, flip and grab is a good first attempt; spins, grinds and manuals offer other approaches. Stay in the court. The timer and type count remain visible while you skate.

A bail or timeout ends the attempt. Return to Mo to replay. The challenge is available in career and free skate and keeps its own session result alongside the ten career goals. Music follows the master and ambience sliders.

### Cat's Got the Beat

Find Rae’s **bin drums and two soft dancing cats** at **George Square’s garden busking pitch** for **Cat’s Got the Beat**. Accept the offer with a settled combo, then grind the three marked coping segments **A → B → C** within 60 seconds. The approach runs east along the garden’s south edge; use the wide square to return and line up again. Each segment must be a real grind capture. You can bank separate lines between segments. After the third, land and bank cleanly, then return to Rae and look toward the drums to see the cats’ little dance.

Repeating the most recent segment adds no progress. A wrong marked segment resets the sequence; starting again on A begins a fresh sequence. A bail, timeout or leaving the busking area ends the attempt. The steady world indicators and HUD show the next segment. Reduced motion uses static raised paws. Return to Rae to replay. The original spatial techno-percussion loop follows Master and Ambience volume, pauses with the game and stops at run end.

New route choices include the low station undercroft beneath the high platform route, Merchant Close's angled passage, a second park descent back toward Central, and the Clyde print-yard loop with a low curved bank and hip. Use the map to find the branches and try both directions.


### Gull-Proof Delivery — through the Barras

Find Mairi's breakfast-parcel stall on the loading terrace below the Barrowland sign. Settle your current combo, then interact to collect the courier bag and start the 60-second delivery. Manual toward the loading steps, ollie the marked **Market Loading Steps** gap and land a clean bank in the same line. Banking too early lets you retry while the clock keeps running.

After the jump, choose the **Covered market** or **Calton lane** entrance, pass its three numbered markers in order and reach the **south delivery counter**. The first marker commits your lane. Steady world markers highlight the next target; the HUD gives its direction and distance. Follow its live left/right/turn-back cue from your actual landing position to hook into the market. A bail, leaving the market or timeout returns the parcel to Mairi. On success, your breakfast is safe and the gull raids a spare wrapper. Look toward the counter for the short response; reduced motion uses a static pose. Return to Mairi to replay. This optional challenge works in either mode and does not add a saved career goal.

### Exchange/gallery skating edges

The gallery entrance has low side banks leading to a raised stone terrace and an angled seating ledge. Use a controlled approach: full speed carries the bank's extra lift past this short ledge. Ollie onto it with Grind held, then ollie off and start a Manual after landing to continue the line. The open apron leads back toward the existing gallery stairs and fountain. These are ordinary skating opportunities; there is no extra challenge offer or saved goal.

The west shopfronts have a separate low seating edge and bank. Ride up and back down, or try its coping, while the broad street beside it remains available for an easier pass. The city map shows the authored local routes. Both attachments are original game layouts informed by Glasgow architecture.

### Service cut-through

Find the signed shutter in the station's service passage. Interact at its switch
to open or close the shortcut; wait until it has lifted before riding through.
The city map updates the route's open/closed state. A doorway sensor refuses or
pauses closing while the skater occupies it. The shutter can be reopened, and
Restart restores it closed. It changes the route without creating a career goal.

### Cone on a Cruise — Clyde quay

Find the steward and foam cone on the north Clyde quay, near the river stunt
ring. Bank your current line, then Interact to begin the **25-second** attempt.
Build a southbound approach, pop just before the painted launch mark and press
Interact again while airborne near it. Your forward speed launches the foam
cone; the cone must pass completely through the ring without clipping its rim
and land on its recovery raft. Keep the skater on the quay, land cleanly and
bank the trick. All of those events are required. An ineligible launch input can
be retried while the clock runs; clipping the rim, missing the ring, bailing,
timing out or leaving the stunt area ends the attempt. The cone returns for another try.
This foam-prop stunt adds no points beyond your ordinary skating line.
It is separate from the career cone interaction.

### One More Lap — Kelvingrove

Find the park regular on the lower promenade near the park's Central connection.
Bank your line and Interact for a **75-second** lap. Your first numbered gate
chooses either the **Full park loop** with six gates, climbing through the upper
park, or the **Grass-bank cut** with five gates. Follow that branch's numbers in
order, land at least one real pop during the attempt, then return to the regular
before time runs out. Skipping a gate, bailing or leaving the park fails the lap.
Return to the start for another attempt. Both branches are available in career
and free skate; their session results do not add saved goals or unlocks.

## Useful playtest notes

Record your computer/OS, keyboard or wired/Bluetooth controller, then note any sticking input, difficult rail capture, unclear balance direction, camera discomfort, unreadable text, missing sound, save failure or route that feels unrewarding. Include the package's `BUILD-METADATA.json` when reporting a defect. Automated Linux checks do not replace this controller and feel review.
