# Durable public board import regressions

The proposed public `tests/board_import_tests.gd` is registered immediately after
render-budget checks, preserving every existing registration including Fitted
and Water. Its default source is the real production board. The retained private
runner overrides only that resource path to the identical admitted candidate.

Native02 is clean 27/0, with parser and both source/launcher hashes stable. It
checks seven decoder/pin/layout/stride/nonfinite/index controls; exact actual
wood positions and nondegenerate UVs; protected native hardware/grip stream
hashes and identity/datum/5696-triangle contracts; executed source/import-policy/
decoder pins; and actual bound RGB8 1024² ten-mip 4,194,303-byte allocation.
These catch the observed lossy compression and unused-alpha resource mistakes.
No player trajectory tests are duplicated. The full actual default-path run and
combined suite remain integration gates.

Rejected01 failed before parsing because the first wrapper omitted private XDG
user/cache paths and the engine tried to create read-only home directories. Its
raw failure is preserved. Native02 changes only wrapper environment settings;
the same proposed test source is used. No test threshold changed.
