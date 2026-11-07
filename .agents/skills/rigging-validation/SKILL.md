---
name: rigging-validation
description: Validate source-authenticated fitted clothes, multi-bone skin deformation and head-to-neck continuity without weakening Tam Hawks Pro Skater contact gates.
---

Read AGENTS.md, docs/STATUS.md, docs/product/AAA_BENCHMARK.md,
docs/planning/FIDELITY_TICKETS.md and docs/architecture/interfaces.md. Load the
rider-fidelity and quality-verification skills. Coordinate disjoint source ownership
with the rider artist and motion engineer before touching a fitter, visual rig or
existing test. The studio director owns integration and Git operations.

Use this skill for fitted mesh replacement and deformation verification, especially
FID-101/102/301 and benchmark V1/V3. A production checkpoint freeze forbids runtime,
asset and existing-test edits; work in an ignored private directory and preserve a
durable plan until the director explicitly releases that stage.

1. Authenticate real source triangle/vertex IDs, UVs and derived clipping
   barycentrics before selecting garment hem, waist, cuff or neck boundaries. Never
   add hidden witness geometry or select an arbitrary height plane to make a fitted
   mesh satisfy a procedural mesh test.
   For wardrobe occlusion, inspect the source asset's authored `delete_verts`
   data and exact original-polygon policy. This outfit hides a source face only
   when all its corners are masked; preserve that quad rule before triangulation.
   Do not replace authored coverage with guessed X/Y cuts or painted holes.
2. Deform each actual indexed native vertex with its own weights, resolved Skin
   binding and Skeleton3D global bone pose. Godot gives a nonempty bind name
   precedence over its index; a missing nonempty name must fail closed rather than
   fall back to a valid index. Include the real skeleton/root
   transform and correct interpolated render frame. Do not substitute hips-only
   deformation for multi-bone trouser triangles or average witnesses for a seam.
   Proxy mappings can reference fitting-cage helper vertices outside the rendered
   BODY graph. A BODY-only field will then transfer zero influence silently. Use
   an authenticated helper correspondence or record an exact closest-body-triangle
   projection, barycentrics and distance; verify the intended field reaches the
   actual collar before rendering.
3. Check every authenticated shared waist edge across shirt/trouser draw splits:
   identical source endpoint IDs, rest positions, weights, normals and posed world
   positions. Importer vertex reordering/UV splits require explicit identity mapping;
   ambiguity must fail rather than choose the nearest convenient point.
   Native Head seam vertices must be referenced by real indices and form every
   authenticated boundary edge; unused/orphan matches are not rendered coverage.
   Check finite UV/normal attributes and directed triangle identity. Derive source
   matching error from the actual import format, separately from contact limits.
4. Preserve all existing attachment, limb length, grab, shoe, tyre, board and finite
   native support tolerances. Keep corrupt torso inverse-bind and uniformly
   translated jacket negative controls. Add a wrong semantic mapping and a missing
   seam-edge control so the new adapter cannot silently omit the defect.
5. Derive neck continuity from the actual retained head crop ring and the real
   Head-to-Torso transforms. Check head yaw/pitch, push facing, deepest crouch/grab,
   bail/get-up and restart. Use correctly bound source skin and a continuous seam;
   reject floating patches, exposed holes, large dark filler and shoulder
   penetration. Preserve existing bone indices if an optional appended neck bone
   is justified; retain pose_body/pose_leg/pose_arm compatibility.
   For a Head-child BoneAttachment3D override, configure the external skeleton and
   binding, enable override, then restore local Transform3D.IDENTITY last. Binding
   while override is disabled can move the attachment into an unintended offset.
   Relative skeleton paths must be refreshed if the Head is reparented. Verify
   immediate pose getters as well as end-of-tick results: queued transform
   notifications can delay the override, especially in synchronous pose tests.
   For rendered observations, use the actual interpolated model API even for an
   OFF descendant, since its ancestors may still interpolate. Check current native
   Skin palettes and rigid node clocks together before changing interpolation.
   A coincident point seam and copied normals are insufficient. Check actual
   adjacent triangle winding, dihedral and coverage of every outer crop boundary;
   the November fitted-neck investigation found two 180-degree folds hidden by
   the earlier collar treatment. Share the real skin material across the seam,
   including roughness, normal and specular settings, then inspect native views.
6. Offline math or glTF inspection is diagnostic only. Coordinate a single engine
   import/render lease, run the actual native deformed geometry checks, inspect
   ordinary Main and close motion views, and reject raw engine/resource errors even
   if assertion totals pass. Use immutable source inventories and exact commands.
7. Report independently witnessed positives, observed defects and unmeasured gates
   separately. If you implemented the fitter or adapter, another QE/BA verifies it.
   Headless algebra cannot accept visual realism, target Mac performance or AAA.

Default future test ownership, only after an explicit stage release:
tests/skater_body_attachment_tests.gd and tests/fitted_garment_tests.gd. Coordinate
shared call sites with the director. Keep source provenance/licence and the rider's
65,000-triangle/64-MiB provisional budgets intact.
