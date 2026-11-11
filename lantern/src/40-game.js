/* HOLLOWMERE — the game: the lamplighter, the villagers, the shades, seven waylights and the Great Lantern */
(function () {
  const G = HM.game = {};
  const U = HM.U, W = HM.world, UI = HM.ui, A = HM.audio, I = HM.input;
  const KEY = 'hollowmere-lanternlight-v1';
  const fresh = () => ({ lit: {}, great: false, petals: 0, taken: {}, oil: false, wren: false, bramble: false, x: 3, z: 21 });
  let S = G.state = fresh();
  let scene, q, npcs = [], shades = [], raiseT = 0, pending = null, stepAcc = 0, saveT = 0, dawnGo = false, need = 3;
  const P = G.player = { pos: new THREE.Vector3(3, 0, 21), vel: new THREE.Vector3(), yaw: Math.PI, speed: 0, strength: 1, hurt: 0 };
  G.light = { pos: new THREE.Vector3(), col: new THREE.Color(1.0, 0.6, 0.27), i: 0, raw: 0, range: 18 };

  G.hasSave = () => { try { return !!localStorage.getItem(KEY); } catch (e) { return false; } };
  const save = () => { S.x = P.pos.x; S.z = P.pos.z; try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) {} };
  const load = () => { try { const t = localStorage.getItem(KEY); if (t) return Object.assign(fresh(), JSON.parse(t)); } catch (e) {} return null; };
  const litCount = () => W.waylights.filter((w) => w.lit).length;

  /* ---------- villagers ---------- */
  const CAST = [
    { id: 'wren', name: 'Wren, the old lamplighter', x: 4.3, z: 15.6, look: { skin: 0xb98f73, robe: 0x4a3a2c, mantle: 0x2a221b, hair: 0x9a9a96, hat: 'cap', hatCol: 0x3b2c20, beard: 0xa9a9a4, scale: 0.97 } },
    { id: 'mirabel', name: 'Mirabel, apothecary', x: -2.3, z: -11.3, look: { skin: 0xc79a7c, robe: 0x2f4a3c, mantle: 0x1c2d25, hair: 0x5a2f1c, hat: 'wizard', hatCol: 0x1f3229, scale: 0.94, long: true } },
    { id: 'bramble', name: 'Bramble, hedge-witch', x: -15.2, z: -15.4, look: { skin: 0xa77d62, robe: 0x3c2f3f, mantle: 0x241c27, hair: 0x1c1714, hat: 'hood', scale: 0.92, long: true } },
    { id: 'pip', name: 'Pip', x: 5.4, z: 3.6, look: { skin: 0xd1a588, robe: 0x6b4a2c, mantle: 0x7a2f26, hair: 0x7a4a22, hat: 'none', scale: 0.7 } },
    { id: 'pellam', name: 'Sir Pellam, watchman of the stones', x: -41.2, z: 6.8, look: { skin: 0xb48c74, robe: 0x39404c, mantle: 0x5a2222, hair: 0x777777, hat: 'helm', beard: 0x8a8a88, scale: 1.03, belly: 1.12 } },
  ];
  const talk = {
    wren: () => {
      if (!S.wren) return { lines: [
        'So the Academy sent someone after all. Good. You have a pole and a flame, and that is most of the trade.',
        'Seven waylights ring this valley. They went dark the night the Great Lantern guttered, and the gloom has been walking in ever since.',
        'Start with the gate post, just up the lane. Stand beneath it and lift your flame.',
        'Mind the shades out past the walls. They cannot bear a lit post, but they will drink your lantern down if you let them close.'], then: () => { S.wren = true; save(); } };
      if (S.great) return { lines: ['Forty years I lit those posts, and I never once saw the morning come in like that.', 'You will do, lamplighter. You will do.'] };
      const n = litCount();
      if (n === 0) return { lines: ['The gate post, just up the lane. Stand under it and lift your flame.'] };
      if (n < 7) return { lines: ['' + n + ' of seven. I can see further down the lane already.', 'Follow the paths out from the square. Every one of them ends at a post.'] };
      if (!S.oil) return { lines: ['All seven. Now the big one in the square, and that wants Starlight Oil. Mirabel presses it, behind the shrine.'] };
      return { lines: ['You have the oil. Go on. The whole valley is holding its breath.'] };
    },
    mirabel: () => {
      if (S.great) return { lines: ['Look at the colour of that sky. I had forgotten it did that.'] };
      if (S.oil) return { lines: ['The oil is yours. Pour it into the Great Lantern once all seven waylights are burning.'] };
      if (S.petals >= need) return { lines: ['Moonpetals, and fresh. Give me a moment at the pot...', 'There. Starlight Oil. It burns cold and it burns a very long time.', 'It will only take in the Great Lantern, and only when the seven are lit around it.'], then: () => { S.oil = true; S.petals = 0; A.pick(); UI.toast('Received Starlight Oil'); save(); } };
      return { lines: ['The Great Lantern will not catch on lamp oil. It wants Starlight Oil, and I can press that.', 'Bring me ' + need + ' moonpetals. They open blue beside still water, where the ground goes soft.' + (S.petals ? ' You have ' + S.petals + ' so far.' : '')] };
    },
    bramble: () => {
      if (S.great) return { lines: ['The Thornwood is sleeping easy. First time since autumn.'] };
      if (!S.bramble) return { lines: ['You are bound for the post at the wood’s edge? The Thornwood has shut itself. It does that when it is frightened.', 'Here, a hedge-word. Say it at the post and the briars will remember their manners.'], then: () => { S.bramble = true; A.pick(); UI.toast('Learned the hedge-word'); save(); } };
      return { lines: ['Speak the word softly. The wood is listening, and it does not like to be shouted at.'] };
    },
    pip: () => {
      if (S.great) return { lines: ['It is MORNING! I am going to find every puddle in the valley.'] };
      const n = litCount();
      return { lines: n ? ['I counted from the roof. ' + n + ' light' + (n > 1 ? 's' : '') + ' now!', 'If a shade gets close, run for a lit post. That is what I do.'] : ['Are you the new lamplighter? Your lantern is the only light I have seen all week.', 'The shades do not like lamps. If one gets close, run for a lit post.'] };
    },
    pellam: () => {
      if (S.great) return { lines: ['Dawn over the stones. My watch is ended, and gladly.'] };
      return { lines: ['I have kept watch at these stones forty winters. I can keep it one night more.', 'The flame in the square was first lit by the founder of Ashenvale. While it burns, the gloom stays behind the hills.', 'Light the post here, and I will see anything that tries the western road.'] };
    },
  };

  function buildShade() {
    const g = new THREE.Group();
    const dark = new THREE.MeshStandardMaterial({ color: 0x010203, roughness: 1 });
    const body = new THREE.Mesh(new THREE.ConeGeometry(0.42, 2.1, 9, 4, true), dark); body.position.y = 1.05; g.add(body);
    const head = new THREE.Mesh(new THREE.SphereGeometry(0.2, 10, 8), dark); head.position.y = 2.05; head.scale.y = 1.25; g.add(head);
    const em = new THREE.MeshBasicMaterial({ color: new THREE.Color(1.6, 2.6, 4.5) });
    for (const sx of [-1, 1]) { const e = new THREE.Mesh(new THREE.SphereGeometry(0.022, 6, 5), em); e.position.set(sx * 0.065, 2.08, 0.185); g.add(e); }
    scene.add(g);
    return { g, pos: new THREE.Vector3(), home: null, tx: 0, tz: 0, k: 0, t: Math.random() * 9, wait: 0 };
  }
  function placeShade(s) {
    const dark = W.waylights.filter((w) => !w.lit);
    if (!dark.length) { s.home = null; return; }
    s.home = dark[Math.floor(Math.random() * dark.length)];
    for (let i = 0; i < 20; i++) {
      const a = Math.random() * 6.283, d = 5 + Math.random() * 9; s.pos.set(s.home.x + Math.cos(a) * d, 0, s.home.z + Math.sin(a) * d);
      if (HM.height(s.pos.x, s.pos.z) > HM.WATER_Y && s.pos.distanceTo(P.pos) > 14 && Math.hypot(s.pos.x, s.pos.z) > 17) break;
    }
    s.tx = s.pos.x; s.tz = s.pos.z; s.k = 0;
  }

  G.init = (sc, quality) => {
    scene = sc; q = quality;
    P.h = HM.human.givePole(HM.human.build({ skin: 0xc9a182, robe: 0x27314d, mantle: 0x141a2c, hair: 0x2c2119, hat: 'wizard', hatCol: 0x141a2c }));
    scene.add(P.h.root);
    P.lamp = new THREE.PointLight(0xffa24a, 0, 20, 1.7); P.lamp.castShadow = q.lampShadow > 0;
    if (P.lamp.castShadow) { P.lamp.shadow.mapSize.set(q.lampShadow, q.lampShadow); P.lamp.shadow.camera.near = 0.25; P.lamp.shadow.camera.far = 20; P.lamp.shadow.bias = -0.004; P.lamp.shadow.normalBias = 0.05; P.lamp.shadow.radius = 2; }
    scene.add(P.lamp);
    for (const c of CAST) {
      const h = HM.human.build(c.look); h.root.position.set(c.x, HM.height(c.x, c.z), c.z); scene.add(h.root);
      W.colliders.circles.push({ x: c.x, z: c.z, r: 0.34 });
      npcs.push({ def: c, h, x: c.x, z: c.z, face: Math.atan2(-c.x, -c.z) });
    }
    need = Math.min(3, W.herbs.length);
    for (let i = 0; i < q.shades; i++) shades.push(buildShade());
  };

  G.begin = (isNew) => {
    S = G.state = (isNew ? null : load()) || fresh();
    for (const w of W.waylights) w.setLit(!!S.lit[w.def.id], true);
    W.great.setLit(S.great, true); W.dawn = S.great ? 1 : 0; dawnGo = S.great;
    for (const h of W.herbs) { h.taken = !!S.taken[h.id]; h.group.visible = !h.taken; h.src.target = h.src.i = h.taken ? 0 : 1.6; }
    P.pos.set(S.x, 0, S.z); P.strength = 1; W.lit = litCount();
    shades.forEach(placeShade);
    G.started = true;
    if (isNew || !S.wren) UI.card('Hollowmere', 'The waylights have gone out', 5);
  };

  function kindle(w) {
    raiseT = 1.5; pending = () => {
      w.setLit(true); S.lit[w.def.id] = true; W.lit = litCount(); HM.gfx.params.flash = 0.5; A.chime(false);
      UI.card(w.def.name.replace(/^the /, 'The '), W.lit + ' of ' + W.waylights.length + ' waylights burning', 4);
      if (W.lit === W.waylights.length) UI.toast('All seven burn. The Great Lantern waits in the square.', 6);
      save();
    };
  }
  function kindleGreat() {
    raiseT = 2.2; pending = () => {
      W.great.setLit(true); S.great = true; S.oil = false; HM.gfx.params.flash = 1.2; A.chime(true); dawnGo = true;
      UI.card('Dawn over Hollowmere', 'The long night is ended', 9); save();
    };
  }

  /* what the lamplighter can do right here */
  function nearest() {
    let best = null, bd = 1e9; const px = P.pos.x, pz = P.pos.z;
    const consider = (x, z, r, label, fn) => { const d = Math.hypot(px - x, pz - z); if (d < r && d < bd) { bd = d; best = { label, fn, x, z }; } };
    for (const n of npcs) consider(n.x, n.z, 2.3, 'Speak with ' + n.def.name.split(',')[0], () => { const t = talk[n.def.id](); UI.say(n.def.name, t.lines, t.then); });
    for (const w of W.waylights) if (!w.lit) consider(w.x, w.z, 2.6, 'Kindle the waylight', () => {
      if (!S.wren) { UI.toast('Someone is waiting by the gate. Speak with them first.'); return; }
      if (w.def.needs === 'bramble' && !S.bramble) { UI.toast('Briars have closed over the post. Someone who knows the wood might help.', 5); return; }
      kindle(w);
    });
    if (!W.great.lit) consider(0, 0, 4.2, 'Kindle the Great Lantern', () => {
      if (litCount() < W.waylights.length) { UI.toast('The Great Lantern will not catch while the valley is dark. ' + litCount() + ' of 7 waylights burn.', 5); return; }
      if (!S.oil) { UI.toast('It needs Starlight Oil. Mirabel the apothecary can press it.', 5); return; }
      kindleGreat();
    });
    for (const h of W.herbs) if (!h.taken) consider(h.x, h.z, 1.7, 'Gather moonpetal', () => { h.taken = true; S.taken[h.id] = true; h.group.visible = false; h.src.target = 0; S.petals++; A.pick(); UI.toast('Moonpetal gathered (' + S.petals + ')'); save(); });
    return best;
  }

  G.objective = () => {
    if (S.great) return 'Dawn has come to Hollowmere. Wander as you please.';
    if (!S.wren) return 'Speak with the lamplighter waiting by the gate';
    const n = litCount();
    if (n === 0) return 'Kindle the waylight at the South Gate';
    if (n < 7) return 'Relight the waylights of the valley';
    if (!S.oil) return S.petals >= need ? 'Bring the moonpetals to Mirabel, behind the shrine' : 'Gather ' + need + ' moonpetals by still water for Mirabel';
    return 'Kindle the Great Lantern in the square';
  };
  const tv = new THREE.Vector3();
  G.target = () => {
    if (S.great) return null;
    const np = (id) => { const n = npcs.find((m) => m.def.id === id); return tv.set(n.x, 1.9, n.z); };
    if (!S.wren) return np('wren');
    let best = null, bd = 1e9;
    const dark = W.waylights.filter((w) => !w.lit);
    if (dark.length) {
      const open = dark.filter((w) => !(w.def.needs === 'bramble' && !S.bramble));
      if (!open.length) return np('bramble');
      for (const w of open) { const d = Math.hypot(w.x - P.pos.x, w.z - P.pos.z); if (d < bd) { bd = d; best = w; } }
      return tv.set(best.x, 2.9, best.z);
    }
    if (S.oil) return tv.set(0, 3.9, 0);
    if (S.petals >= need) return np('mirabel');
    for (const h of W.herbs) if (!h.taken) { const d = Math.hypot(h.x - P.pos.x, h.z - P.pos.z); if (d < bd) { bd = d; best = h; } }
    return best ? tv.set(best.x, HM.height(best.x, best.z) + 0.7, best.z) : np('mirabel');
  };

  const mv = new THREE.Vector3(), lw = new THREE.Vector3();
  G.update = (dt, time, camYaw) => {
    const busy = UI.talking || raiseT > 0 || !G.started;
    // --- walk ---
    I.poll();
    let ix = busy ? 0 : I.mx, iz = busy ? 0 : I.mz;
    const fx = -Math.sin(camYaw), fz = -Math.cos(camYaw), rx = Math.cos(camYaw), rz = -Math.sin(camYaw);
    mv.set(rx * ix + fx * -iz, 0, rz * ix + fz * -iz);
    const mag = Math.min(1, mv.length()); if (mag > 0.001) mv.normalize();
    const hgt = HM.height(P.pos.x, P.pos.z), wade = U.smooth(HM.WATER_Y + 0.02, HM.WATER_Y - 0.3, hgt);
    const top = (I.run ? 4.5 : 2.5) * (1 - wade * 0.5) * mag;
    P.vel.x = U.damp(P.vel.x, mv.x * top, 9, dt); P.vel.z = U.damp(P.vel.z, mv.z * top, 9, dt);
    const nx = P.pos.x + P.vel.x * dt, nz = P.pos.z + P.vel.z * dt;
    const ok = (x, z) => HM.height(x, z) > HM.WATER_Y - 0.36 && Math.hypot(x, z) < HM.WORLD_R;
    if (ok(nx, nz)) { P.pos.x = nx; P.pos.z = nz; } else if (ok(nx, P.pos.z)) { P.pos.x = nx; P.vel.z = 0; } else if (ok(P.pos.x, nz)) { P.pos.z = nz; P.vel.x = 0; } else { P.vel.set(0, 0, 0); }
    W.resolve(P.pos, 0.32);
    P.pos.y = U.damp(P.pos.y, HM.height(P.pos.x, P.pos.z), 14, dt);
    P.speed = Math.hypot(P.vel.x, P.vel.z);
    if (P.speed > 0.25) P.yaw += U.angDiff(P.yaw, Math.atan2(P.vel.x, P.vel.z)) * Math.min(1, dt * 10);
    P.h.root.position.copy(P.pos); P.h.root.rotation.y = P.yaw;
    HM.human.animate(P.h, dt, P.speed, raiseT > 0);
    stepAcc += P.speed * dt; if (stepAcc > 0.78) { stepAcc = 0; A.step(hgt < HM.WATER_Y + 0.06); }
    // --- the act ---
    if (raiseT > 0) { const before = raiseT; raiseT -= dt; if (pending && before > 0.7 && raiseT <= 0.7) { const p = pending; pending = null; p(); } }
    const near = busy ? null : nearest();
    if (near) UI.prompt(near.label); else UI.noPrompt();
    if (I.consumeAct()) { if (UI.talking) UI.advance(); else if (near && !busy) near.fn(); }
    // --- villagers turn to watch you pass ---
    for (const n of npcs) {
      const d = Math.hypot(P.pos.x - n.x, P.pos.z - n.z), want = d < 7 ? Math.atan2(P.pos.x - n.x, P.pos.z - n.z) : n.face;
      n.h.root.rotation.y += U.angDiff(n.h.root.rotation.y, want) * Math.min(1, dt * 2.5);
      HM.human.animate(n.h, dt, 0, false);
    }
    // --- shades ---
    let safe = W.great.lit || Math.hypot(P.pos.x - 0.9, P.pos.z - 0.5) < 6;
    for (const w of W.waylights) if (w.lit && Math.hypot(P.pos.x - w.x, P.pos.z - w.z) < 12) safe = true;
    let drain = 0;
    for (const s of shades) {
      if (!s.home || s.home.lit || W.great.lit) { s.k = U.damp(s.k, 0, 3, dt); if (s.k < 0.03) { placeShade(s); if (!s.home) { s.g.visible = false; continue; } } }
      else s.k = U.damp(s.k, 1, 1.2, dt);
      s.t += dt; s.g.visible = s.k > 0.03;
      const dp = Math.hypot(P.pos.x - s.pos.x, P.pos.z - s.pos.z);
      let nearLit = false; for (const w of W.waylights) if (w.lit && Math.hypot(s.pos.x - w.x, s.pos.z - w.z) < 13) nearLit = true;
      if (Math.hypot(s.pos.x, s.pos.z) < 15) nearLit = true;
      let sp = 0.7;
      if (nearLit) { s.tx = s.home.x; s.tz = s.home.z; sp = 2.2; }
      else if (dp < 11 && !safe && G.started) { s.tx = P.pos.x; s.tz = P.pos.z; sp = 1.75; }
      else if ((s.wait -= dt) < 0 || Math.hypot(s.tx - s.pos.x, s.tz - s.pos.z) < 0.6) { const a = Math.random() * 6.283, d = 3 + Math.random() * 8; s.tx = s.home.x + Math.cos(a) * d; s.tz = s.home.z + Math.sin(a) * d; s.wait = 5 + Math.random() * 6; }
      const dx = s.tx - s.pos.x, dz = s.tz - s.pos.z, dl = Math.hypot(dx, dz);
      if (dl > 0.3) { s.pos.x += dx / dl * sp * dt; s.pos.z += dz / dl * sp * dt; s.g.rotation.y += U.angDiff(s.g.rotation.y, Math.atan2(dx, dz)) * Math.min(1, dt * 3); }
      s.g.position.set(s.pos.x, HM.height(s.pos.x, s.pos.z) - 0.1 + Math.sin(s.t * 1.3) * 0.06, s.pos.z);
      s.g.scale.set(0.8 + s.k * 0.2 + Math.sin(s.t * 2.1) * 0.04, s.k, 0.8 + s.k * 0.2);
      if (dp < 1.9 && s.k > 0.5 && !safe) drain = Math.max(drain, 1 - dp / 1.9 + 0.35);
    }
    P.hurt = U.damp(P.hurt, drain > 0 ? 1 : 0, 4, dt);
    P.strength = U.clamp(P.strength + (drain > 0 ? -0.3 * drain : safe ? 0.3 : 0.015) * dt, 0.22, 1);
    // --- the carried flame ---
    P.h.root.updateMatrixWorld(true); P.h.lantern.getWorldPosition(lw);
    const fl = 1 + Math.sin(time * 11) * 0.04 + Math.sin(time * 27.3) * 0.025 + P.hurt * Math.sin(time * 40) * 0.25;
    const raw = (5 + 23 * P.strength) * fl * (1 + (raiseT > 0 ? 0.4 : 0)) * (1 - W.dawn * 0.75);
    P.lamp.position.copy(lw); P.lamp.intensity = raw; P.lamp.distance = 9 + 12 * P.strength;
    P.h.lantern.userData.glass.material.emissiveIntensity = 3 + 7 * P.strength * fl;
    G.light.pos.copy(lw); G.light.raw = raw; G.light.i = raw * 0.05; G.light.range = P.lamp.distance;
    // --- dawn ---
    if (dawnGo && W.dawn < 1) W.dawn = Math.min(1, W.dawn + dt / 38);
    HM.gfx.params.flash = U.damp(HM.gfx.params.flash, 0, 2.2, dt);
    HM.gfx.params.sat = 1 - P.hurt * 0.55;
    UI.setObjective(G.objective()); UI.setCounts(litCount(), W.waylights.length, S.petals, S.oil); UI.setFlame(P.strength);
    if ((saveT += dt) > 8) { saveT = 0; if (G.started) save(); }
  };
  G.debug = { kindle: (i) => { const w = W.waylights[i]; w.setLit(true, true); S.lit[w.def.id] = true; W.lit = litCount(); }, set: (o) => Object.assign(S, o), dawn: () => { W.great.setLit(true, true); S.great = true; dawnGo = true; }, shades: () => shades.map((s) => [s.pos.x, s.pos.z, s.k]) };
})();
