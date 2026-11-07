# Parsed keyboard and controller selection

The private Main/HUD/world integration passes **31/0** using actual native parsed
keyboard and pad events. It navigates title and pause menus, cancels to the correct
origin with opener focus restored, switches both ways between Merchant District
and City Tour, waits for a held accept button to release, then starts and resumes
free skate without an accidental trick. The prior world is freed and the same
isolated Music object survives. No personal profile is written.

Parser/native PIDs 135564/135583 ran 13:21:59–13:22:42 UTC on 7 November 2026,
42.349 seconds within the declared 180-second aggregate bound. Logs are clean;
all 897 recorded source inputs stayed exact. Another bounded secondary native
cohort overlapped; these are functional results, not performance measurements.
This is parsed input, **not a physical controller test** or real-time human review.

Rejected epoch 01 contains three fixture parse errors. Rejected epoch 02 reports
27/4: it assumed three Down presses reached Choose Level, overlooking focusable
controls in the live Music card. Epoch 03 changes only the fixture to traverse
with actual Down presses until the visible destination (bounded to fourteen).
Its log records four presses in each device cohort. Production HUD code did not
change to obtain the positive result. All rejected logs/maps/probes are retained.

The source closure inherits 895 exact inputs from
[Main lifecycle 02](../main-lifecycle-02/README.md) and adds the before-bound outer
launcher and parsed-input fixture. The successful source count is 897; its native
cache was not before-hashed. The archived launchers contain historical local
paths and should not be executed from this evidence directory. Run `verify.py`
for offline archive/source verification; it does not start an engine.
