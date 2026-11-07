# Private finite Manual bearing recovery proposal

This proposal remains uninstalled. Its one-file payload is based on current actual
Skater `1ef6cdb7dfe2942d1d3aa8f025d89213e2f1f06500fcfb588b7d18734de27f84`
and produces `09fe4402cb7f0631bcc88094037700206aaf3571afc7a6231bd411f829121e5c`.
The actual full regression03 keeps its source freeze.

The reproduced Station legacy candidate failure is an actual trailing loaded tyre
intersecting its own finite 70 mm Cylinder3. At physics319, native shape overlap
reports the exact tyre/cylinder pair while `get_rest_info` returns an empty
Dictionary. The original first-pass loaded-wheel vertical rays already hit this
same finite RID/integer shape with walkable normals; an empty rest result currently
prevents the existing bounded correction from being tried.

The candidate authorizes that existing correction only from an original ray earned
in the same physics callback, for the same restored board frame and loaded wheel,
with exact native body/RID/integer-shape agreement. It rejects missing/malformed/
nonfinite proof, stale stamps/frames, foreign or multiple owners, Area RIDs,
nonwalkable normals, mode/floor loss and unloaded wheels. It stores no cross-frame
authority. Body trajectory, Manual pitch, collision geometry, original 25 mm maximum,
8 mm raised-fit skin, and final four-tyre/complete-board native tests stay unchanged.

## Declared cost

The new proof helper adds **zero spatial queries**: it reuses two first-pass rays
and makes one body shape-count metadata getter on an eligible proof. This is not
a zero-cost or constant-frame-time claim. Previously refused cases can now reach
the existing restore/downcast/refinement path. With four tyres and 32 cached model
components, that function's conservative spatial-call upper bound is
`4*4 + (4+32) + 10*(4+32) = 412`: each initial tyre can overlap/rest/raised-overlap/
downcast, followed by final tyre/model validation, then up to ten complete native
refinement poses (upper, eight bisections, final). Short-circuit rejections usually
use fewer calls. This is a source bound for one restore invocation, not an observed
histogram, whole-frame bound or target-M5 cost acceptance. The overlap result cap
changes from1 to16; saturation fails closed. No new mesh/shape/PackedArray or
per-physics persistent geometry cache is built. Temporary proof Dictionaries and
references are allocated only on restore calls; `board_contact_geometry()` returns
a small Dictionary referencing immutable already-cached arrays.

## Evidence and pending gates

- `station-manual-branch-01`: raw shutdown/resource errors; rejected, causal trace only.
- `station-manual-branch-02`: clean native 2/1 original rejected model, 1004 physical rows.
- `station-manual-candidate-03`: parser failure; no native acceptance.
- `station-manual-candidate-04`: diagnostic-instrumented 3/0; all 1004 physical rows
  exactly equal branch02; actual original crest correction 11.430168 mm.
- `station-manual-candidate-05`: diagnostic-instrumented 21/0, original route plus
  17 synchronous adversarial checks. Historical wrapper scope strings remained
  copied from the baseline and are superseded only by this explicit qualification;
  raw receipts are immutable. The clean payload tightens collider type to
  PhysicsBody3D after that epoch.
- `station-manual-clean-06`: observer parser type-inference error, no native run.
- `station-manual-clean-07`: parser hit declared5s bound after only engine banner,
  no raw script error and no native launch.
- `station-manual-clean-08`: prepared parser15/native105 within120s; not yet run.
  It binds source plus private imported bytes, UID and class caches; adds an actual
  Area RID fault and uses a declared transient12 mm negative display fixture only
  after priority100 records the ordinary actual pose. Those diagnostic queries
  and display mutations are not gameplay or runtime-cost proof. The actual pose
  restores before camera/next physics. Every ordinary model frame is still checked.

Next: clean-source coherent native run, exact1004-row physical parity, independent
review, affected native Manual/contact neighbors and any public regression before
Root considers actual installation. This is a shared legacy Manual-contact repair;
it does not certify the newly requested compact Merchant Yard design.
