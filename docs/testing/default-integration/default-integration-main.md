# Main reconciliation

Owned only game/main.gd. No other runtime/test/tool/docs edits, staging or commit.

Retained default behavior: interpolation OFF on Main; facade A/B construction
metadata; world.get_transition_features -> Skater.set_transition_features;
render-time HUD refresh; career.presentation_revision/source-object cache;
graphics quality and input-profile settings; per-axis special input edge gate;
default string bail_phase/blocked feedback and recovered callback.

Integrated work behavior: real FeatureHub startup/pause/reset/finish/polling;
side-offer priority and cancellation; actual route-change/map union; launch,
landing, bank and bail activity callbacks; accepted-entry SPECIAL gain/tick;
identity-based repetition, spin/hold bonuses, flip upgrade; full state HUD payload.
Both lip and lip_active keys remain, with bail_phase:string and bail_progress:float.

Semantic repairs beyond textual conflict resolution:
- Removed duplicate reset_interactions invocation.
- Snapshot all actual side components once per HUD frame (old fixed three-element
  cache would index past its end after FeatureHub adds two challenges).
- Resolve real display name/stance styling/catalog aliases when retained paths
  emit a name with a stale last_trick_id. FS/BS rotation extends a trick instead
  of adding a multiplier entry; recognized trick family drives audio/encounters.
- Entry, hold and upgrade signals each connect once. No bank-time SPECIAL gain.
- Keep physical ordinary transition carving out of combo-link continuation.
- Suppress rolling-contact audio during associated transition air even if native
  MoveAndSlide floor flags still describe the prior supported frame.

Source audit: every stage2 and stage3 Main function retained; each of five trick/
recovery signals connects exactly once; reset_interactions count1; bank recharge0;
no conflict markers. Main parse is initially blocked by unresolved HUD and
market_encounter dependencies; no Main-local parser errors in that attempt.
Root/QE own merged native tests; await their controller/world completion.
