# ADR-033 — Normal Main includes the owner's trial content

Date: 25 October 2026. Status: accepted by explicit owner direction.

The owner expects merged features to be available when launching main for trial.
Keeping the implemented station/train, pond/ducks, central green and civic return
behind a launch flag prevented that trial and confused implementation with access.

Main now supplies `pt24_design_preview=true` by default before World construction.
Normal editor, source and exported launches include all four additions without
arguments. The old `--pt24-design-preview` option remains a compatible alias.
An explicit false metadata value remains a diagnostic baseline control; it is
not selected automatically for tests, script launches or disabled persistence.

Existing inventory fixtures declare that historical baseline explicitly. Default
Main integration and normal scene boot instead set no content override and verify
the actual station/train, pond, paired tree relocations and native civic quarter.
Test persistence and Music control remain isolated independently of level content.

Mac performance, moving shadows, physical controls, Music and human acceptance
remain open evidence requirements. They do not hide merged trial features or
imply that ordinary trial enablement has passed those requirements. No new
geometry, service, release, spending or unrelated feature is authorized here.
