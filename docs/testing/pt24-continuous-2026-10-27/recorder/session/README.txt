Tam Hawks Pro Skater playtest session
Share the ZIP after ending the session. Each issue has a PNG, JSON state and your note.
1 capture; 2 session menu; 3 finish. Numbers type normally while entering a note.
Player axes: forward is -Z; camera forward is separate. Raw transforms/state describe the frozen physics tick. Presentation transforms and capture frame/timestamps identify the PNG drawn after freezing.
Native on_floor is the last move_and_slide result; native_floor_valid and gameplay airborne/feature flags distinguish startup and authored support. Configured trick IDs are not active-state evidence. bail_reason is historical; bail.active_reason applies only during a bail.
Raw local evidence is retained if ZIP export fails.
