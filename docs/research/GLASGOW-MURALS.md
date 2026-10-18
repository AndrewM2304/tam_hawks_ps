# Glasgow mural references and original wall-painting proposal

Research inspected **18 October 2026**. This dossier supports the existing M03-007/M05-001/M06-007 place and art work; it does not add a playable area or certify final art. The official trail and artist interview were fetched through the configured cloud proxy, at no cost. No Google Maps API, Street View texture, downloaded artwork asset, generated image service or paid resource is used.

**Current state: implemented, measured, and disabled in normal play.** The original startup-only helper is retained in [glasgow_murals.gd](../../game/levels/glasgow_murals.gd), but its strict A/B/A frame-spike admission failed in Exchange, George, Station and the botanical-wall view. Root set `arcade_murals_preview` to default `false`; explicit diagnostics can still construct the paintings. [The retained evidence](../testing/arcade-response/murals/README.md) contains 2,880 measured native frames, source receipts and six selected actual screenshots. Capture integrity passed; performance admission and final realistic-art acceptance did not. There is no Mac performance result or inferred FPS improvement.

The paintings below are original Glasgow-inspired designs, not replicas of the named artists' works or claims that their murals occupy these compressed game locations. Permission to inspect public reference material is not a licence to redistribute its images. Exact recreations would require a separately verified reuse basis; none is asserted here.

## Inspected factual sources

The [official City Centre Mural Trail overview](https://www.citycentremuraltrail.co.uk/About) identifies the programme as a Glasgow City Council initiative, says its first artwork was produced in 2008, and describes improving otherwise tired buildings and lanes. This is useful context for large paintings on real building faces rather than freestanding game signs. Its [current mural list](https://www.citycentremuraltrail.co.uk/murals/murallist) was also inspected.

| Work and source | Attribution and date actually supported | Real location actually supported | Confidence and limit |
| --- | --- | --- | --- |
| [Saint Mungo](https://www.citycentremuraltrail.co.uk/murals/muralabout/22) | Smug; completed February 2016. The source says the work was officially untitled and acquired this popular name. | High Street; official embedded map marker `55.860889, -4.238278`. | High for official attribution/location/history. Page/photo is not an October 2026 condition survey. |
| [Fellow Glasgow Residents](https://www.citycentremuraltrail.co.uk/murals/muralabout/28) | Smug; no completion date stated in inspected page. Animals from Glasgow parks/green space appear through painted openings. | Gable overlooking the Ingram Street car park, Merchant City. | High for official description/location; current physical condition unverified. |
| [Honey… I Shrunk The Kids](https://www.citycentremuraltrail.co.uk/murals/muralabout/42) | Smug, identified as Sam Bates; no completion date stated here. | Mitchell Street just off Argyle Street; official marker `55.858984, -4.256059`. | High for official attribution/location. Do not infer precise wall dimensions from the page. |
| [The World's Most Economical Taxi](https://www.citycentremuraltrail.co.uk/murals/muralabout/41) | Rogue-One. [Art Pistol's project account](https://www.artpistol.co.uk/new-taxi-does-hundreds-of-miles-to-the-balloon), published **15 April 2013**, independently describes its commissioning and painting. | Mitchell Street at the Argyle Street end, explicitly named by Art Pistol; official marker `55.858548, -4.255911`. | High: official trail plus the project's own account. Publication date is not asserted to be the exact completion date. |
| [Wind Power](https://www.citycentremuraltrail.co.uk/murals/muralabout/40) | Rogue-One and Art Pistol; conceived for Doors Open Day **2014**, celebrating sustainable energy. | Official marker `55.859750, -4.255811`; nearby Central Station/GoMA, per page. | High for source description and marker. Street name is not inferred solely from coordinates. |
| [Cult of St Enoch](https://www.citycentremuraltrail.co.uk/murals/muralabout/88) | Smug; described as a refreshed interpretation of an earlier mural, informed by Rebecca Sharp's *Maiden Mother Mage*. No completion date given. | George Street/High Street context; official marker `55.860500, -4.239830`. | High for the current listing. Older lists describing the mother-and-child composition should not be treated as current without verification. |

The coordinates above are values read from the trail page's embedded marker data. No map API was invoked, and they are not survey measurements.

Artist evidence: [Art Pistol's direct interview with Rogue-One](https://www.artpistol.co.uk/rogue-one-graffiti-artist-talks-to-us-about-his-latest-street-art), published **19 October 2012**, describes his Clyde Street mural process: large emulsion background fields, sky/water colour transitions, then outlined figures and detail. It also records his intention to brighten the city and give passers-by something engaging to see. This supports readable composition, human scale and painting tied to the actual wall; it grants no reproduction licence. The [Art Pistol Projects street-art portfolio](https://artpistolprojects.com/street-art/) confirms named projects including Wind Power, Floating Taxi, Under the River Clyde and Woman in Black Royal Exchange Square; it is an inspected project index, not proof of every work's present condition.

The official source photographs for [Saint Mungo](https://www.citycentremuraltrail.co.uk/MuralImages/22BACK.jpg), [Fellow Glasgow Residents](https://www.citycentremuraltrail.co.uk/MuralImages/28BACK.jpg), and [Taxi](https://www.citycentremuraltrail.co.uk/MuralImages/41BACK.jpg) were opened and visually inspected. They show detailed, shaded painting whose masonry surface remains perceptible, not raised sculptural props. These cropped reference photographs do not establish full-wall dimensions. They remain temporary research files outside the repository; they are not sampled, traced, bundled, or used as textures.

Access limits recorded honestly: `www.glasgow.gov.uk/muraltrail` returned HTTP 403; `www.smugone.com` returned 503, while the non-www domain led to a domain-sale page and was rejected as artist evidence. A guessed `rogue-one.co.uk` address redirected to an unrelated Disney page and was also rejected. `www.rogueoner.com` returned a proxy tunnel 403. The accessible direct Rogue-One interview and official trail supply the artist evidence above; no artist was contacted.

## Agreed existing wall contract

Source inspected: [city construction](../../game/levels/glasgow_square.gd), `_build_city` around line 399, `_build_merchant_close` around line 506, `_building` around line 735; [FacadeKit](../../game/levels/art/facade_kit.gd), `decorate` and `_return_windows`. `_building` makes a closed body of local depth 12 m, and front/return decoration occupies local Z+6 and the side ends. The two selected local Z−6 rear faces have no authored shop/window decoration. They are existing solid buildings, so painting adds no route or collision.

| Original game painting | Existing transform and wall extent | Authored canvas bounds in world metres | Composition and purpose |
| --- | --- | --- | --- |
| **Clyde Heron** | West Exchange central tenement: position `(-41,0,0)`, yaw `PI/2`, width 30, height 16, depth 12. Rear face at X−47, Z−15…15, Y0…16. | Plane X **−47.018**, outward normal −X; Z **−10…6**, Y **3.1…11.1**. | Original side-profile heron with extended neck, reeds and broad river ribbons. Muted petrol, cream, slate and ochre, with shaded feather/wing shapes. No Smug portrait, robin-in-hand or painted broken-wall arrangement. Visible from the supported Station retail service shoulder and approaching Central streets. |
| **Printworks Bloom** | Print Works: position `(-77.5,2.5,-55)`, yaw `PI/2`, width 18, height 14, local Z scale 0.7. Rear face at X−81.7, Z−64…−46, Y2.5…16.5. | Plane X **−81.718**, outward normal −X; Z **−61…−49**, Y **3.4…10.4**. | Original large thistle/leaf sweep with a wheel-like seedhead and curved ink bands. Restrained plum, moss, cream and warm red; no artist signature, borrowed slogan or floating text. Fits the fictional print-works context and the existing supported Merchant service court. |

The 18 mm outward offset is a paint-skin allowance, not a new wall or physical ledge. All shapes share the same 18 mm plane. One ordered alpha-one painter surface draws after opaque scenery, tests its depth, and writes no paint depth; overlapping eyes/feathers therefore cannot compete in the depth buffer. The earlier seven 2 mm strata were rejected in source review before visual admission. All triangles remain inside the authored rear-face rectangle, clear of its foundation, roof, corners and side returns. Shapes leave masonry visible around them, with no picture frame or fabricated three-dimensional shadow. Sampled curves describe the heron's neck, wing, feathers and river lines; tapered strokes describe the thistle's florets and leaf veins. Neither title is an in-world sign or assertion of an actual Glasgow mural name.

## Rendering and integration budget

- One startup-only helper, `GlasgowMurals.build(world, materials) -> Node3D`; idempotent under a stable `GlasgowMurals` child. Root owns the world call and default admission.
- **Two wall-local one-surface meshes, one shared alpha-one vertex-colour painter material, 1,092 actual triangles against the 1,200 limit**; native AABBs stay local to each painting, with a 45 m visibility range. No whole-map merged bounds. Two possible main draws are the authored maximum; each measured mural-facing view adds one reported draw.
- **Zero new textures, custom shaders, lights, physics objects, routes, labels, process callbacks, or shadow passes.** The transparent render pass still has sorting/overdraw cost although every paint colour has alpha 1. Cast and receive shadows are OFF. Unshaded vertex colour is toned once at construction for these two rear walls.
- Mesh geometry and colours are newly authored original data. No source photographs, borrowed SVGs, extracted artist linework, stock icons or model downloads enter the repository.
- Declared upper bounds are not measured performance. The completed frozen-source A/B/A test failed its strict p95/p99 admission despite meeting the geometry budget. The helper and previously rejected backdrops remain OFF. In failing Exchange, George and Station observations, draw/primitive counters show no additional mural submission; this dataset does not prove that mural rendering caused those spikes. The unchanged gate still rejects admission.

The source exports `CANVASES`, `VIEWS` and `mural_report` metadata for independent checks/captures. Counts are **539 heron + 553 botanical = 1,092 triangles**, confirmed by native construction and the retained renderer report. `mural_report.chunks` records actual mesh counts, local AABBs, wall rectangles, wall X and shared material instance IDs. Captured static front views are `(-62,7,-2) → (-47.018,7,-2)` and `(-92,7,-55) → (-81.718,6.9,-55)`; approach, close and oblique variants are in `VIEWS`. These are authored observers, not a natural-input gameplay replay.

The six retained 960×600 images show the original bird and botanical silhouettes attached to the selected walls. Root reviewed front/approach composition, and the art author inspected all six retained views. Close views remain flat, graphic prototypes: visible coarse contours, sparse tonal modelling and minimal convincing paint/masonry interaction do not meet the owner's final realistic mural ambition. Still images do not certify temporal flicker, 1080p appearance, human fun or Mac performance. Research of the city's much more detailed murals remains valid independently of this rejected implementation.

## Acceptance and resumption

1. **Contract, source and bounded native capture complete; normal-play admission rejected.** Keep the default OFF. Root owns any future integration/default change. Preserve the raw measurements and the documented metadata discrepancy in the evidence README.
2. Resource checks cover two meshes, shared material, the triangle budget, planar alpha-one paint, disabled depth writes with depth testing, no shadows, 45 m visibility range and idempotence. Further independent wall-ray support and natural camera checks remain useful before any future admission; no collision or route is added by the paintings.
3. Improve realistic paint detail only as a separately budgeted experiment. Future actual chase-camera approaches and moving close/grazing views must cover 1080p and the owner-relevant smaller viewport. Check attachment, temporal stability, readable silhouettes and masonry interaction without obscuring architecture or gameplay prompts. Current static images are not final-art approval.
4. Any future candidate needs fresh frozen-source matched rendering measurements and the existing unchanged gates. Do not retry an unchanged candidate until a favourable sample appears, infer FPS from draw counts, or attribute culled-view spikes to paint without evidence. Actual Mac owner comfort and final visual acceptance remain open.
5. Keep source attribution for research separate from authorship of the original game art. If later pursuing a particular named mural, record actual permission/compatible licence and approved reproduction/credit requirements before shipping it; no permission is claimed by this dossier.

### Fetch receipts

SHA-256 values below identify the HTML/image bytes actually inspected on 18 October 2026, rather than a search snippet. Source HTML and reference photos were held only in `/tmp/tam-hawks-mural-research`; URLs and findings above are the durable record. A future page may change.

| Source | SHA-256 |
| --- | --- |
| Official About | `68353ed77c2410ef4b747303a1f4eb2305575bb65bceea292762c51f3aae1ea8` |
| Official mural list | `713502490a13072fe6e30a0f17274c6927c2ecf813595fba71d108bf9e9dd166` |
| Saint Mungo page | `9f435fde6f0d88416b636de0f74fec7727917e50bdf4a40506b18f7709e37a65` |
| Fellow Glasgow Residents page | `5e9aefb68b9f77911e4ef13912bdb2214187aeb50bdf1191b9617bed32ee860e` |
| Honey… page | `be403e5c4f57c6d220f2c579e33dd24b5d0bc2fb0fc2c97c14bb3a38b398b47c` |
| Taxi page | `a847b8b38a3f15cb5963961dfdcab16c769c58d7e1fb8049c2068c39f82b0a58` |
| Wind Power page | `2b8de43452cd6b3998bf2a0bd0b5de0edd56b1dea11828e8eb066af8cde8d4f2` |
| Cult of St Enoch page | `962a716db19f1648ed74ba27ae29f19f2c00fd3662548bff48aaa9654b793ca7` |
| Rogue-One interview | `46547cf6496a13abd7150aa3a4fef4524bccc03929e05ec2b469990138fb9673` |
| Art Pistol Taxi account | `7ce337086acd0791a1cf586a32e4b8fc43569af46306ddeec477c81264e97cf2` |
| Art Pistol Projects street-art index | `76f90288a6f005466919b75be0019296084076dbcd5ce7a08fd996bd5cd654e1` |
| Saint Mungo reference JPEG | `307a4767abd3cee78668d703542b4ee1083266306622712958fa20c5c2b5e1f8` |
| Fellow Glasgow Residents reference JPEG | `f134f1400f3dcae8971a16dcbeb24dc5e0da2360cfb776ee50367452892c65b4` |
| Taxi reference JPEG | `c8260a16057c55ea8042919c3de1da9fd8f5757d05dcaeeb9bc87e9b97642d0f` |
