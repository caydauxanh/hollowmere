/* HOLLOWMERE — main: quality, camera, loop */
(function () {
  const U = HM.U, I = HM.input, W = HM.world, G = HM.game, UI = HM.ui;
  const qs = new URLSearchParams(location.search);
  const coarse = matchMedia('(pointer: coarse)').matches;
  const TIERS = {
    high: { grass: 170000, shadow: 2048, pool: 5, lampShadow: 512, shades: 7, maxScale: 1.5, px: 2.6e6 },
    mid: { grass: 95000, shadow: 1024, pool: 4, lampShadow: 256, shades: 6, maxScale: 2, px: 1.5e6 },
    low: { grass: 45000, shadow: 1024, pool: 3, lampShadow: 0, shades: 5, maxScale: 1, px: 0.7e6 },
  };
  const q = TIERS[qs.get('q')] || (coarse ? TIERS.mid : TIERS.high);
  let scene, camera, scale = 1, last = 0, time = 0, slow = 0, fast = 0, frames = 0, titleOn = true;
  const camPos = new THREE.Vector3(), tgt = new THREE.Vector3(), v = new THREE.Vector3();

  function resize() {
    const w = innerWidth, h = innerHeight, dpr = Math.min(devicePixelRatio || 1, q.maxScale);
    const cap = Math.sqrt(q.px / (w * h * dpr * dpr));
    HM.gfx.resize(w, h, dpr * Math.min(1, cap) * scale);
    camera.aspect = w / h; camera.fov = w < h ? 54 : 42; camera.updateProjectionMatrix();
  }

  function frame(now) {
    requestAnimationFrame(frame);
    const dt = Math.min(0.05, (now - last) / 1000 || 0.016); last = now; time += dt; frames++;
    // keep it smooth: shed resolution when frames run long, win it back when they do not
    if (frames > 90 && !qs.get('fix')) { if (dt > 0.03) slow++; else if (dt < 0.019) fast++; if (slow > 70 && scale > 0.5) { scale *= 0.84; slow = fast = 0; resize(); } else if (fast > 900 && scale < 1) { scale = Math.min(1, scale * 1.12); slow = fast = 0; resize(); } if (slow + fast > 1200) slow = fast = 0; }
    const P = G.player;
    let yaw = I.yaw, pitch = I.pitch, dist = 6.6 * I.zoom, side = 0;
    if (titleOn) { yaw = 0.5 + Math.sin(time * 0.07) * 0.3; pitch = 0.13; dist = 7.4; side = innerWidth > innerHeight ? 1.7 : 0; }
    G.update(dt, time, yaw);
    tgt.set(P.pos.x + Math.cos(yaw) * side, P.pos.y + 1.5, P.pos.z - Math.sin(yaw) * side);
    v.set(tgt.x + Math.sin(yaw) * Math.cos(pitch) * dist, tgt.y + Math.sin(pitch) * dist, tgt.z + Math.cos(yaw) * Math.cos(pitch) * dist);
    v.y = Math.max(v.y, Math.max(HM.height(v.x, v.z), HM.WATER_Y) + 0.45);
    if (frames < 3) camPos.copy(v); else { camPos.x = U.damp(camPos.x, v.x, 12, dt); camPos.y = U.damp(camPos.y, v.y, 12, dt); camPos.z = U.damp(camPos.z, v.z, 12, dt); }
    camera.position.copy(camPos); camera.lookAt(tgt); camera.updateMatrixWorld();
    W.update(dt, time, P.pos, P.pos, G.light);
    const gp = HM.gfx.params;
    gp.focus = camPos.distanceTo(tgt); gp.dof = titleOn ? 1 : 0.7;
    gp.exposure = U.lerp(1.0, 0.62, W.dawn); gp.bloom = U.lerp(0.6, 0.3, W.dawn); gp.vignette = 1 + P.hurt * 0.9;
    HM.audio.mood(W.lit / 7, W.dawn);
    // a small brass mark shows where the next thing to do lies
    const t = !titleOn && !UI.talking ? G.target() : null;
    if (t && Math.hypot(t.x - P.pos.x, t.z - P.pos.z) > 5) {
      v.copy(t).project(camera); const behind = v.z > 1;
      let sx = (v.x * 0.5 + 0.5) * innerWidth, sy = (-v.y * 0.5 + 0.5) * innerHeight;
      const m = 34, cx = innerWidth / 2, cy = innerHeight / 2;
      if (behind) { sx = cx - (sx - cx) * 50; sy = cy - (sy - cy) * 50 + 9999; }
      const off = behind || sx < m || sx > innerWidth - m || sy < m + 40 || sy > innerHeight - m - 60;
      if (off) { const dx = sx - cx, dy = sy - cy, k = Math.min((cx - m) / Math.abs(dx || 1), (cy - m - 50) / Math.abs(dy || 1)); UI.marker(cx + dx * k, cy + dy * k, true, Math.atan2(dy, dx) + Math.PI / 2, true); }
      else UI.marker(sx, sy - 14, true, Math.PI, false);
    } else UI.marker(0, 0, false, 0);
    UI.update(dt);
    HM.gfx.render(scene, camera, time);
  }

  HM.start = () => {
    HM.gfx.init(document.getElementById('c'));
    scene = new THREE.Scene(); camera = new THREE.PerspectiveCamera(42, 1, 0.3, 420);
    W.init(scene, q); UI.init(); G.init(scene, q);
    I.pitch = 0.3; I.yaw = 0.35;
    resize(); addEventListener('resize', resize); addEventListener('orientationchange', () => setTimeout(resize, 200));
    const begin = (isNew) => () => { titleOn = false; document.getElementById('hud').classList.remove('off'); G.begin(isNew); };
    if (qs.get('skip')) begin(qs.get('skip') === 'new')(); else UI.showTitle(G.hasSave(), begin(false), begin(true));
    window.__g = { HM, q, tp: (x, z) => G.player.pos.set(x, HM.height(x, z), z), cam: (y, p, z) => { I.yaw = y; I.pitch = p; I.zoom = z || 1; }, act: () => { I.actEdge = true; }, frames: () => frames, scale: () => scale,
      info: () => ({ frames, scale, lit: W.lit, herbs: W.herbs.length, pos: [G.player.pos.x, G.player.pos.z], state: G.state, calls: HM.gfx.renderer.info.render.calls, tris: HM.gfx.renderer.info.render.triangles }) };
    requestAnimationFrame(frame);
  };
})();
