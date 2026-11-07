# Closed basin — fresh native buffer allocation

**The512-triangle candidate adds10,580native buffer bytes, within64KiB. Source-stable on799inputs; zero native failures. Visual integration remains open.**

The fresh process records the original256-triangle mesh first, creates the candidate afterward, replaces the sole displayed mesh and releases the original before the final record. A weak reference confirms its release; each state completes the same twelve natural render frames inherited from the existing allocation observer. [Native report](basin-buffer-report.json), [receipt](receipt.json), [preservation](preservation.json).

Buffers change7,452,376→7,462,956bytes; both states have one draw/surface and the same material, camera, light and viewport. Native primitives change256→512. Texture allocation stays25,478,846bytes. No new material, map, light or mesh node is introduced by the replacement.

This measures an isolated LinuxGL rendering-buffer delta, not whole-game or target-Mac memory. The process does not construct Main or claim images, frame time, normal-speed shadows or final art. The closed mesh still needs matched actual Main seam/exterior-shadow review and original gameplay contact/cohort checks before production promotion.
