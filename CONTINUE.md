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
