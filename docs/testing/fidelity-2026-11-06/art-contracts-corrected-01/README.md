# PBR, horizon and guide contract corrections — focused subset

**74 passed /0 failed**, native headless exit0, no script/resource errors,
790 exact game/test/tool/project inputs unchanged. [Receipt](receipt.json),
[original log](engine.log) and [executed observer](observer.gd.txt).
The run took45.468s; this is diagnostic wall duration, not game/Mac performance.

The existing complete TrickScore UI checks, ParkFinish ownership/native geometry
checks and Horizon sky/frontage/foundation checks run unchanged except these
explicit adaptations to the implemented art:

- Grass ownership requires the actual shared CityArt/Outdoors grass resource,
  replacing its obsolete ShaderMaterial class assumption.
- Neutral daylight's declared colour/energy and lower fog density replace the
  historical warm calibration. ACES, fog colour/sky affect and all geometry and
  foundation limits remain.
- Eight original facade masses require the exact brick or sandstone normal map;
  the old no-normal assumption no longer describes the photographic library.
- The manual-guide layout test locates the new350ms instruction copy and retains
  every text-wrap, complete-line, scroll and viewport assertion.

This closes those reproduced contract assumptions only. It is not complete
regression, art acceptance, final rider or hardware acceptance. The preceding
integrated6311/25 failure packet remains separate. This wrapper did not record a
UTC start field; source/raw output are retained without inventing one.
