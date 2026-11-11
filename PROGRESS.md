# Tiến độ Hollowmere

## Bản 2 (28/10/2026, đêm)
- Dựng lại toàn bộ với bộ model KayKit: pháp sư có mũ + gậy, nhà mái lam, tháp đá, học viện xa, đền nến, đèn lồng, bí ngô, núi đồi, mây
- Camera góc nhìn thứ ba mới, bộ điều khiển mới (CharacterBody3D, animation chuyển mượt, có animation hái và niệm chú)
- Hướng màu: hoàng hôn tím cam, đêm xanh lam với đèn ấm, đom đóm
- Vẫn giữ: ngày/đêm giờ thật, 3 luống thảo dược, vạc, lưu game. Test tự động pass.

## Bản 1 (28/10/2026)
- Prototype đầu bằng Kenney city + nhân vật Godot Plush (đã bỏ)

## Việc tiếp theo (gợi ý)
1. Chơi thử trên PC, chỉnh tốc độ đi, độ nhạy camera theo cảm giác tay
2. Thay luống thảo dược và vạc (đang vẽ bằng khối) bằng model đẹp hơn
3. NPC đầu tiên đứng trước quán (tavern), nói chuyện bằng AI qua server riêng
4. Vào được trong tháp (nội thất bằng bộ Dungeon)
5. Bán thuốc, tiền, trang trí
6. Mùa theo tháng thật; điều khiển cảm ứng cho điện thoại

## Bản 3 (29/10/2026) — Thế giới & cốt truyện
- Lore Hollowmere / Học viện Ashenvale / Đêm Lặng; thư mở đầu từ Hiệu trưởng Oriel Vance
- 4 dân làng (Wren, Mirabel, Bramble, Sir Pellam): giới thiệu, trò chuyện theo mức tình bạn, đi ngủ 21:30–6:30
- Bảng tin: 2 yêu cầu mỗi ngày thật (deterministic theo ngày), giao đồ → coins, Ember, tình bạn
- 3 công thức: Starlight Potion, Warmth Tonic, Dream Draught (menu ở vạc)
- Ember 0/12 → cổng Học viện mở (chương sau)
- Nhật ký (nút Journal), lưu toàn bộ tiến độ

## Bản 4 (29/10/2026, chiều) — Chương 2: Học viện Ashenvale
- Cảnh mới `world/academy.tscn`: sảnh lớn (cờ, bàn dài, bục Hiệu trưởng), Hall of Flame (đông), Greenhouse (tây); vào qua cổng khi Ember ≥ 12, ra bằng cửa "To Hollowmere"
- 3 nhân vật mới: Hiệu trưởng Oriel Vance, GS Alder (dạy Kindle), GS Isolde (dạy Verdant)
- Hệ phép: nút/phím 1 Kindle (thắp đèn tắt, +1 Ember), 2 Verdant (cây lớn nửa chu kỳ, 1 lần/luống/ngày); animation niệm chú + hạt màu
- 4 đèn lồng tối trong làng (nhãn "dark lantern"); thắp đủ 4 → báo Hiệu trưởng: +30 coins, +5 Ember, hoàn thành chương 2
- Nhật ký ghi phép đã học và tiến độ chương
- Test tự động end-to-end pass (học phép → thắp lò → về làng → 4 đèn → Hiệu trưởng)

## Bản 5 (29/10/2026, tối) — Chương 3: Thư viện, mùa, chợ, thư
- Thư viện (cánh bắc Học viện): Archivist Quill + 5 cuốn sách lore đọc được (Founding, Quiet Night, Thornquist's Herbal, First Flame, What the Ember Is)
- Nhiệm vụ chương 3: nhặt 3 trang catalogue phát sáng trong làng (giếng, tháp, cối xay) + đọc 5 sách → Quill mở công thức Ember Elixir (+3 Ember mỗi lọ), +40 coins, +6 Ember
- Pip (con Bramble, nhân vật nhỏ) ở cạnh giếng
- Mùa theo tháng thật (màu đất), thời tiết theo ngày (clear / misty / rain, tuyết mùa đông), hiện trên bảng tin và nhật ký
- Thư mỗi sáng ở bảng tin: một dân làng gửi lời + quà (coins hoặc thảo dược)
- Chợ (cạnh building_market): mua 4 món trang trí đặt vào làng (bí ngô, ghế, cột đèn, cờ Học viện), mỗi món +1 Ember, lưu lại
- Test tự động end-to-end pass

## Bản 6 (29/10/2026, tối) — Lớp UI
- Màn hình tiêu đề (Continue / New game) trên nền làng
- Chân dung nhân vật render từ model 3D (SubViewport) trong hộp thoại; tên theo màu nhân vật
- Bộ sưu tập "Villagers": thẻ 9 nhân vật, bóng đen khi chưa gặp, sao tình bạn
- Chuẩn bị ô chân dung để thay bằng tranh AI 2D khi có

## build 20261029-2329 — Overworld
- World bounds ±115; ground 400×400; thinner fog so the far landscape reads.
- Lake Mirren (east) with organic shoreline, dock, reeds, lilies, lantern; not walkable.
- River Wend winds from the lake south-west; stone bridge where it crosses the Fernmoor road; river banks block the player except at the bridge.
- Fernmoor: second village (green roofs, well) south-west, with Hatch the ferryman (daily requests, letter).
- Watchtower ruins on the north-east hill (landmark text).
- Signposts on the three roads. Trees, tree clusters, pines and water all have colliders (tested headless: trees/lake BLOCKED, bridge PASSED).

## build 20261030-0006 — Districts, lessons, daily life
- Four districts around the square, each with a signpost + landmark: Hearth Row (homes, W), Lantern Market (E), Festival Green (S), Trial Field (NW).
- Merchants: Tamsin (buy herbs / sell potions, 8-18), Gorrin the smith; decor stall moved to the market.
- Villager schedules: market mornings, Festival Green 17-19, home in Hearth Row 19-21:30, sleep after; NPCs walk between spots.
- Academy timetable: Flamecraft 8-11 (Alder), Herbology 11-14 (Isolde), Lore 14-17 (Quill), Assembly 17-20 (Oriel). 3-question quizzes → Marks, ranks (Novice→Mage). Timetable boards at the gate and in the Great Hall; journal shows it.
- Trial Field: 3 daily cold braziers (Kindle) + 3 practice beds (Verdant) → Marks. Festival Green: Spark Targets minigame (30 s Kindle), maypole, bonfire, lily pond with stepping stones.
- Tested headless: schedules, shop buy/sell, lesson quiz flow, assembly, targets round, trial marks.

## builds 20261030-0036 … 0058 — "Ashenvale" night pass
- Castle: common room (4 Order beds, banners, hearth, Order board, sleep-until-morning), Potions Dungeon (Master Corvin, class cauldron), Astronomy Tower (Professor Lowe, telescope, star-dome), grander exterior with towers and banners.
- Orders: sorting ceremony with the Headmistress (4 questions) → Emberwing / Tidewatch / Thornhollow / Moonquill; Marks feed Order points; badge in the clock panel.
- Timetable now 6 lessons: Flamecraft 8-11, Herbology 11-14, Lore 14-17, Assembly 17-19, Potions 19-21, Astronomy 21-24. Daily homework from one teacher (notice board + journal).
- Spells: Glimmer (3, staff light + reveals 8 star shards after dark), Mend (4, repairs 8 broken fences/posts). Chapter 4 (three constellations at the telescope), Chapter 5 (Watchtower brazier, epilogue with Oriel), companion star after Chapter 4.
- Broom (Gorrin, 60 coins; B to fly, UP/DOWN buttons on touch), ring course on Festival Green. Staff crystals (cosmetic). Duelling Club with Sir Pellam (Trial Field 14-16). Fishing at the dock (3 fish, Tamsin buys). Gifts to villagers (favourites +3).
- World: Ashford hamlet (Nell, 6 wandering sheep you can pet), Heron Isle in the lake (Old Marrow, dark lantern) reached by Hatch's boat; world map (M); district title cards; moon, stars, wisps at night; fireworks over Festival Green at 20:00; grass, mottled ground, rim light, vignette.
- Audio: procedural music (day/night), ambience, lake water, chime/spell SFX, mute button. UI scales to any screen (canvas_items stretch).

## builds 20261030-0104 … 0131 — second night pass
- Cel-shaded look in the valley (Toon material pass: 2-band light + rim), world map (M / Map button), district title cards, opening camera sweep on a new game.
- Four students (Tobin, Lark, Fen, Ivy — one per Order) follow the timetable room to room; teachers gather for Assembly; Oriel works in her new Study (east of the common room) with the Quiet Night letter (readable after Chapter 5).
- Founders' Cards: 12 chests across valley and Academy. Villager memories at close friendship (16 private stories). Gifts (favourites). Lantern Oil & Heron Broth recipes (full marks in Potions). Garden expansion from Tamsin. Chapter 6: Heron Isle lantern.
- Life: three cats and a library cat, sheep, NPCs face you and gesture, fireworks at 20:00, moon and stars, Hollowmere Gazette on the notice board, Market Day (Sat) and Lantern Walk (Sun) events, teacher letters.
- Settings: ♪ mute, HQ/LQ quality (auto-low on phones: no grass, no MSAA, shorter shadows), pinch-to-zoom, UI scales to any screen.
- Regression suite in tools/ (districts, spells, broom, castle, lesson, isle, ch6, gifts, memories, cards); web smoke test clean.

## builds 20261030-0136 … 0155 — third pass
- Chapter 7 finale (the small star, Star Stone on Festival Green, credits). Your cottage (the Apothecary, west of the garden): bed, hearth, cauldron, trophy shelf, cat, furniture bought at the market; post owl outside with the morning letter.
- The Hollow Wood (north-west): dead trees, graves, crypt, mist, Nightcap beds (night-only herb), Wennet the Grey (ghost, night only) and the Shade Draught recipe; a 13th Founders' Card.
- Sky lanterns (10, for broom riders), flowers and butterflies, bird flocks, floating candles in the great hall, Wren's daily mail route, Pip's mornings with the cat, 45 new chat lines, objective hint line under the bag, typewriter dialogue, more request types.
- Light culling by distance (GL renderer), quality toggle, fuzz test of every interactable in all three scenes (0 failures).

## builds 20261030-0157 … 0227 — fourth pass
- Lesson practicals (Kindle the brazier, Verdant a bed, read in class, brew in the dungeon, observe at the telescope) each worth a Mark; daily Order task from your Order's student; bedtime "day's ledger" summary.
- Talking founder portraits above the dais; hidden cellar behind a sliding shelf in the Potions Dungeon (Mirabel's unlabelled bottle); Restricted Shelves annex east of the tower with three true books (Quill unlocks at Ember 30).
- Objective hint line in the HUD, labels fade with distance, prop visibility ranges and light culling for mobile, wider camera on the broom.
- Full regression (20 tests) + fuzz of every interactable in three scenes + web smoke test: all clean.

## builds 20261030-0233 … 0307 — fifth pass
- The Lantern & Ladle tavern (Hearth Row): evenings 18-21:30 Wren, Mirabel, Bramble, Pellam, Tamsin, Gorrin sit inside; tally board, buy a round for the house.
- Dilly the Fernmoor baker + Fernmoor Fish Pie (students love it); Fen's blue Moonpetal secret; Pip's daily hide-and-seek (9-14); Nell's stubborn sheep (lead it home).
- Ask anyone about the Quiet Night / their work (20 NPCs); Honours (20 achievements, in the journal); drinkable potions in the cottage (haste, starlight, dream sleep, shade); Wood Run second broom course; Heron Isle fishing spot (more Moonfish); Academy bell at every lesson change; ring of fires at the shrine; rain ambience; Academy music; plaza cobbles + star mosaic; seasonal blossom/tints.
- Download shrunk to ~11 MB (unused character animations stripped on import). Villager cards open a details page. README rewritten as a manual.

## builds 20261030-0321 … 0326
- Night Patrol with Sir Pellam (after 21:30, 4 posts in 3 minutes). Four student favours (Tobin, Lark, Fen, Ivy). Pumpkin patch (real-day growth) and Saturday contest. Birthdays (gifts count triple). Photo mode (P). Puddles, rainbow after rain, winter snow piles. Bag listing in the journal.

## build (morning fix) — trees, bridge, bounds
- World bounds were still ±45 (invisible wall before the bridge/Fernmoor/ruins): now ±118, 60 high (broom).
- Hand-built stylised trees (oak, pine, birch, autumn pine, shrub) with sway + cel shading replace the hex-pack tree tiles; every trunk has a real cylinder collider (339 trees). Leaves between the camera and the player dissolve so the view never goes dark inside a canopy.
- Stone bridge is walkable: deck + two ramps + rails; river walls are solid everywhere except under the deck. Hills and mountains have colliders.

## build 20261030-1542 — solid world pass
- Every placed model that you can bump into now gets an automatic collider from its mesh bounds (buildings, walls, fences, crates, barrels, graves, crypt, tents…); tiles, paths, flags, clouds, water plants and small decor stay walkable.
- Road audit (physics probes along every road): nothing sits on a road any more — moved a house, a pine, Ashford's windmill/house/sheep pen/lantern/signpost, a Fernmoor house and the lumber mill, Hatch, a ruin, the shepherd's chest; the lake road now ends at the shore.
- Dock rebuilt as a walkable pier with rails; lake colliders carved around it (fishing spot and Hatch's boat at the pier end).
- Hills no longer land on places (Hollow Wood bed was walled in). Reachability test: flood-fill from spawn reaches every land interactable (only Heron Isle needs the boat).
- Verified in a real browser build (Playwright): house, church, tree, river, lake all block; movement works.

## build 20261031-0106 — movement & life pass
- Player: smooth acceleration/braking (frame-rate independent), lean into turns, floor snap + constant slope speed, coyote time, jump buffer, variable jump height, shallow-angle wall sliding. Camera: eased look-ahead, softer vertical follow, wider FOV when running.
- Tap-to-walk is routed through the NavGrid (walks around houses instead of into them).
- NavGrid (`world/nav_grid.gd`): walkability lattice built from the scene's colliders a few frames after load (2.5 m in the valley, 1.5 m indoors), edges tested with shin/chest rays + surface continuity, A* with road preference (`Village.nav_cost`), string pulling, edges learned bad at run time.
- Walker (`world/walker.gd`): base for villagers, cats and sheep — real CharacterBody3D capsules (layer 2) so they block and are blocked, smooth speed/turning, separation from each other, stuck recovery; hidden walkers stop colliding and stop simulating.
- Villagers walk their schedules along roads and over the bridge, stroll a few steps near their post and come back, face you when you approach, and stand on the nearest clear spot when a hand-placed post was inside a building box. Pets/sheep follow with rate-limited re-planning.
- Fixed: hex-pack fences were rotated 90° and offset one tile (drawn as combs, colliders off the picture). `Village._fence_piece` places them on the line; gates have the door leaf hidden (open gateway); sheep pen is a closed ring with one opening. Trial Field is now reachable through its gate.
- Tests: `tools/test_nav.gd` (routes, villagers arrive, nothing inside colliders), `tools/test_navacad.gd` (academy rooms), `tools/test_move.gd` (feel + tap routing + solid villagers); full suite re-run clean.

## build 20261111 — story intro, quest compass, see-through walls, analog stick
- Opening cinematic (`ui/intro.gd`): five slow night-to-morning shots telling the Quiet Night, tap/F to advance, Skip button; plays on the first Begin, then the Academy letter. Camera rig has a `cine_point` override.
- Quest compass (HUD): a gold diamond over the current objective (villager with a request, the gate, a teacher, the nearest dark lantern, the Watchtower, Hatch's boat, the telescope…) with distance; turns into an edge arrow when off-screen; points at the door when the goal is in the other scene.
- See-through occluders: the cel shader (now also indoors: academy, home, tavern) dithers away walls/roofs/props between the camera and the player and anything right against the lens; floors never fade.
- Touch stick is analog: gentle push strolls, full push runs (deadzone 0.15). Debug line reduced to the build id.
- Tests: `tools/test_intro.gd` (intro flow restores state, compass targets per chapter, stick speeds); full suite re-run clean.

## build 20261111 (night) — "lantern-light" picture pass (reference: loktar00/lanternfall)
- `world/post.gd` PostFX: one full-screen pass under the HUD — split-tone grade (cool shadows / warm lights), filmic S-curve, vignette, film grain; stronger at night. Also on the indoor scenes.
- Night relit: darker, bluer ambient and moon; village lanterns 1.5x; the player carries a warm hand lantern after dark (flicker; casts shadows on high quality); glow/bloom on high quality (now also on web); thicker fog at night and dusk.
- `world/grass.gd`: dense tufted meadow grass (9000 tufts high / 3800 low) in one tile that wraps around the camera; sways, bends away from the player, lit by sun and lanterns; masked off roads, paths, paving, river, lake and pond by a top-down texture built from the same geometry.
- Ground shader: mottled turf, dry patches, muddy hollows and standing water with a real specular reflection (wetter on rainy days).
- UI: EB Garamond (SIL OFL) as the house typeface, dark plates with a thin brass edge for panels and buttons.
- See-through: full clear inside the centre window (no speckle) and anything crowding the lens clears out; academy relit candle-warm.
- `tools/test_quality.gd`: low/high toggles (grass count, glow, lantern shadow) and the night lantern.
