# How to continue this project (any account, Claude or Codex)

Game: **Hollowmere** — cozy magic-school life sim, Godot 4.7.2 (GL Compatibility), GDScript.
Live page: https://claude.ai/artifact/4jqS4QWaJ2Bb6XQRPw8zpK (owner must share "Can edit" for another account to republish).

## Pipeline
1. Godot 4.7.2 headless + export templates (`web_nothreads`, `windows`) — see publish.sh.
2. `bash publish.sh` → exports web build, splits engine wasm into part00..02.wasm (<15 MB each), renames pack to game.pck.wasm, stamps BUILD id into ui/hud.gd and web/hollowmere.html.
3. Publish web/hollowmere.html as the artifact with files ["game.pck.wasm"] (+ part*.wasm, engine.js on first publish).
4. Tests: `tools/test_*.gd` are autoload test scripts; run with `--headless -- --fresh --hour=H` after temporarily adding `T="*res://tools/test_x.gd"` under [autoload]. `webphys.js` drives the real web build in headless Chromium (window.__dbg / window.__cmd bridge in ui/hud.gd).
5. Screenshots: `xvfb-run godot --path . -- --fresh --hour=H --cam=x,z,yaw,pitch,dist --shot=out.png`.

See PROGRESS.md for the full feature history and README.md for the player manual.

## 2026-11-12 — Lanternlight remake (three.js) is now the live game
The user rejected the Godot look and asked for a full redo in the style of loktar00's Lanternfall.
The live artifact (same URL) now serves `lantern/dist/index.html`; the Godot project stays in this repo untouched.
- Source: `lantern/src/*.js` (core, gfx HDR pipeline, world, human, audio, ui, game, main), template `lantern/page.html`.
- Build: `node lantern/build.js` -> `lantern/dist/index.html` (three r160 inlined, single file). Publish that file to the artifact URL.
- Tests (Playwright + swiftshader): `node lantern/flow.js` (full quest start to dawn), `node lantern/mob.js` (iPhone touch stick), `node lantern/shot.js out.png 1280 720 'q=high&skip=new&fix=1' '<js>'` for screenshots. Debug hooks: `window.__g`.
- Next ideas: more villagers/quests, interiors, Academy visit after dawn, better faces/cloth, camera collision.
