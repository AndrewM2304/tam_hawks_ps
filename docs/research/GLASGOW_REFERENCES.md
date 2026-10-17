# Glasgow streets and shopfront references

**Research date:** 17 October 2026. **Tasks:** M03-006 (verification), M03-007 (boundary facades), M05-001 (production art). The owner wants recognisable Glasgow shops, venues and street layouts around the skating areas. This dossier preserves inspected evidence and the exact next research steps; it is not an approved layout or a current business directory.

## Evidence available now

The runtime network proxy rejected official sites, Google Maps/Street View and OpenStreetMap with `Tunnel connection failed: 403 Forbidden`. No street imagery or map layout was inspected. The reference-domain additions now appear in the saved environment base configuration (read returned no pending draft), yet this running machine still rejects fresh requests. Fresh-task access using the saved configuration has not been verified. Retry at next environment startup before asking the owner to change the same settings again. Maps may require additional image hosts; add only hosts demonstrated necessary, without enabling billing or a paid API.

A reachable community source provides **dated address leads only**:

- [Pinned GeoJSON](https://github.com/xiaoyingz444-netizen/glasgow_map/blob/999df17e995612a082c42a5011172c77cf86e4ce/restaurants.geojson), inspected through its [raw file](https://raw.githubusercontent.com/xiaoyingz444-netizen/glasgow_map/999df17e995612a082c42a5011172c77cf86e4ce/restaurants.geojson).
- [Inspected commit](https://github.com/xiaoyingz444-netizen/glasgow_map/commit/999df17e995612a082c42a5011172c77cf86e4ce): authored/committed 17 February 2026 at 19:43:13 UTC.
- 6,415 features with FHRS-shaped fields; newest `RatingDate` in the file is 11 February 2026. SHA-256: `7ff9d67b3657eb3076ea766cf77769f8065c302f46946bd0b4241d5187613995`.
- The repository had no root README, provenance statement or licence file. Primary Food Standards Agency validation was blocked. The dataset was **not imported or redistributed**; individual factual leads below are for follow-up.

`RatingDate` is a historical inspection field in this copy, not verification of current trading, appearance or occupancy. Some distinct businesses share coordinates. Never derive shop order, adjacency, dimensions, entrances, street geometry or collision positions from those points.

| Candidate as recorded | Address as recorded | RatingDate | FHRS ID |
|---|---|---|---|
| Gallery Of Modern Art Cafe | 111 Queen Street Glasgow | 2019-10-17 | 126272 |
| Di Maggio's | 21 Royal Exchange Square Glasgow | 2022-08-04 | 127764 |
| Banca Di Roma | 31 Royal Exchange Square Glasgow | 2025-08-28 | 1552942 |
| The Ivy | 106 Buchanan Street Glasgow | 2025-10-30 | 1170574 |
| Marks and Spencer | 12 Argyle Street Glasgow | 2011-02-07 | 53568 |
| FOPP | 19 Union Street Glasgow | 2014-03-13 | 642521 |
| Tantrum Doughnuts | 28 Gordon Street Glasgow | 2021-10-04 | 1044684 |
| Barras Art And Design (BAaD) | Unit 7 54 Calton Entry Glasgow | 2022-09-08 | 1359566 |
| Saint Luke's + The Winged Ox | 17 Bain Street Glasgow | 2024-10-09 | 1732007 |
| Van Winkle | 267 Gallowgate Glasgow | 2019-07-19 | 1015610 |

Additional inspected Gordon Street candidates: Blue Lagoon, 69 Gordon Street (2025-12-11; FHRS 104180), and The Grand Central Hotel, 99 Gordon Street (2025-10-16; FHRS 1170576). All rows remain unverified for 17 October 2026. Choose a manageable set of distinctive anchors after current checks; this list is not a commitment to model every business.

## Survey plan after access is available

| Area | Questions to resolve from inspected maps and street views | Intended use |
|---|---|---|
| George Square | Establish square outline, civic frontage, adjoining street/corner relationships, entrances, paving and current works. Identify at least three distinctive edge anchors. | Recognisable civic perimeter and skyline around the skating space |
| Royal Exchange Square / Queen Street | Locate GoMA and actual approaches; verify Di Maggio's, Banca Di Roma and current occupants, frontage sides, bays, sign zones, recesses and stone colours. | Detailed court borders, gallery silhouette and believable retail/hospitality edges |
| Central / Gordon / Union / Buchanan / Argyle | Confirm the walking route and corner relationships before compressing it; inspect station massing/canopy, shop order, Tantrum/FOPP candidates and changing street widths. | Station edge and researched shopfront sequences framing a playable route |
| Gallowgate / Barras / Bain Street / Calton Entry | Confirm Barrowland frontage and market entrances; inspect BAaD, Saint Luke's and Van Winkle surroundings, shutters, arches, railings and paving. | Distinct market/venue boundaries and street silhouettes |

These are survey questions, not verified spatial relationships. Preserve useful real adjacency, then explicitly document compression or relocation needed for fun skating. Model shallow facades and convincing upper storeys before considering interiors. Keep decorative details clear of accepted landing zones and camera paths.

For each selected frontage, record:

1. Public source URL, publisher, inspection date and confidence; confirm current occupants against an official source where possible.
2. Street/corner, viewed direction, map relationship and Street View imagery capture date if displayed. Distinguish current observations from older imagery.
3. Observed bay count, proportions, materials, shop signage, entrances, roofline and neighbouring frontage order. Separate observations from estimates.
4. A small original layout sketch based on those observations, with intentional game adaptations labelled; no geographic diagram is claimed yet.
5. Associated facade scene/resource, source/asset attribution and acceptance capture. Mark a location current, historical or intentionally composite.

M03-006 remains **Blocked** until the current location/layout survey meets its acceptance criteria. M03-007 consumes that verified dossier; do not replace generic signs with guesses and call the district authentic.

## Exact source pages to retry

The following pages were attempted on 17 October 2026; all were blocked by the proxy, so their contents were not read:

- [GoMA — Glasgow Life](https://www.glasgowlife.org.uk/museums/venues/gallery-of-modern-art-goma)
- [Princes Square](https://princessquare.co.uk/)
- [Cass Art Glasgow](https://www.cassart.co.uk/stores/glasgow/)
- [Glasgow Central — Network Rail](https://www.networkrail.co.uk/communities/passengers/our-stations/glasgow-central/)
- [Barras Market](https://www.barrasmarket.com/)
- [Barrowland Ballroom](https://barrowland-ballroom.co.uk/)
- [OpenStreetMap city-centre view](https://www.openstreetmap.org/#map=17/55.8595/-4.2536)
- [Google Maps: Royal Exchange Square](https://www.google.com/maps/place/Royal+Exchange+Square,+Glasgow/)
- [Waterstones Argyle Street](https://www.waterstones.com/bookshops/glasgow-argyle-street)
- [Royal Exchange Square overview](https://en.wikipedia.org/wiki/Royal_Exchange_Square)
- [Food Standards Agency record 127764](https://ratings.food.gov.uk/business/127764)

The draft includes exact bare/`www` variants used by these sites. Check actual redirects and runtime access before assuming the saved policy is active. A blocked source is not evidence of its content.

### Access recheck — 17 October 2026, 13:11 BST (12:11 UTC)

After the owner asked to proceed, one parallel read-only request per source retried Google Maps (Royal Exchange Square), Glasgow Life (GoMA), Network Rail (Glasgow Central) and Barras Market at the exact URLs above, with 15-second timeouts. All four again returned `Tunnel connection failed: 403 Forbidden`; no page body, map, current shopfront or Street View imagery was inspected. The saved network draft is therefore not evidence of working runtime access. M03-006 remains blocked; retry only after a relevant environment setting or runtime change. No further unchanged retries, paid API calls or image imports were made.

## Reuse and production boundary

Use free public map/Street View access for research when available. No paid API, key, subscription or billing setup is needed. Reference photographs, panoramas, map tiles and logos are not automatically licensed production textures. Create original geometry/materials or use compatible free assets with recorded permissions in [REGISTER.md](../licences/REGISTER.md). Reference links and observations can preserve the research without bundling source imagery.

The inspected [GlasgowData/GlasgowMapping repository](https://github.com/GlasgowData/GlasgowMapping/tree/3ccd1f32dba5c1b12ac5eb89bfc0be603b9898e2) was rejected as an asset source: its README says “Not to be used for commercial purposes” and “Crown copyright 2016”, and its administrative boundaries do not solve shopfront research. No files were imported.

The current game's fictional signs and procedural buildings remain temporary blockout assets. [ART_DIRECTION.md](../product/ART_DIRECTION.md) and M06-007 require the later detailed environment/UI cleanup and owner review.

## Configuration follow-up during rail implementation

The configuration read returned `draft_id: null` and base version `c74f4d99-ee6c-4535-a6ea-acb860e09938~cecfgver_6ad364de66e4819b8f18cbc79718b37d`, with the requested reference domains present. A subsequent direct check of Google Maps and Glasgow Life still returned proxy tunnel HTTP 403 in the current machine. This distinguishes saved configuration from effective runtime access. No site content was inspected; fresh-task access remains unverified. Do not ask the owner to repeat the previous domain edit without new evidence.
