/* HOLLOWMERE — interface: a quiet serif overlay. All DOM; the markup lives in page.html. */
(function () {
  const UI = HM.ui = { talking: false };
  const $ = (id) => document.getElementById(id);
  const I = HM.input;
  let lines = [], li = 0, onDone = null, toastT = 0, cardT = 0, typeT = 0, full = '';

  UI.init = () => {
    const layer = $('touch'), ring = $('stick'), knob = $('knob');
    const R = 52;
    layer.addEventListener('pointerdown', (e) => {
      HM.audio.start();
      if (UI.talking) { UI.advance(); return; }
      const isTouch = e.pointerType !== 'mouse';
      if (isTouch) I.touch = true;
      if (isTouch && I.stick.id === -1 && e.clientX < innerWidth * 0.45 && e.clientY > innerHeight * 0.3) {
        I.stick.id = e.pointerId; I.stick.ox = e.clientX; I.stick.oy = e.clientY; I.stick.x = I.stick.y = 0;
        ring.style.display = 'block'; ring.style.left = (e.clientX - R) + 'px'; ring.style.top = (e.clientY - R) + 'px'; knob.style.transform = 'translate(0px,0px)';
      } else if (I.look.id === -1) { I.look.id = e.pointerId; I.look.lx = e.clientX; I.look.ly = e.clientY; }
      try { layer.setPointerCapture(e.pointerId); } catch (err) {}
    });
    layer.addEventListener('pointermove', (e) => {
      if (e.pointerId === I.stick.id) {
        let dx = e.clientX - I.stick.ox, dy = e.clientY - I.stick.oy; const l = Math.hypot(dx, dy); if (l > R) { dx *= R / l; dy *= R / l; }
        I.stick.x = dx / R; I.stick.y = dy / R; knob.style.transform = 'translate(' + dx + 'px,' + dy + 'px)';
      } else if (e.pointerId === I.look.id) {
        I.yaw -= (e.clientX - I.look.lx) * 0.0058; I.pitch = HM.U.clamp(I.pitch + (e.clientY - I.look.ly) * 0.004, 0.1, 1.15);
        I.look.lx = e.clientX; I.look.ly = e.clientY;
      }
    });
    const up = (e) => {
      if (e.pointerId === I.stick.id) { I.stick.id = -1; I.stick.x = I.stick.y = 0; ring.style.display = 'none'; }
      if (e.pointerId === I.look.id) I.look.id = -1;
    };
    layer.addEventListener('pointerup', up); layer.addEventListener('pointercancel', up);
    layer.addEventListener('wheel', (e) => { I.zoom = HM.U.clamp(I.zoom * (e.deltaY > 0 ? 1.08 : 0.93), 0.55, 1.7); e.preventDefault(); }, { passive: false });
    const act = (e) => { e.preventDefault(); e.stopPropagation(); HM.audio.start(); if (UI.talking) UI.advance(); else I.actEdge = true; };
    $('act').addEventListener('pointerdown', act); $('prompt').addEventListener('pointerdown', act); $('talk').addEventListener('pointerdown', act);
    $('snd').addEventListener('click', () => { HM.audio.start(); HM.audio.setOn(!HM.audio.on); $('snd').textContent = HM.audio.on ? 'Sound on' : 'Sound off'; });
  };

  UI.setObjective = (t) => { if ($('obj').textContent !== t) $('obj').textContent = t; };
  UI.setCounts = (lit, total, petals, oil) => { $('cnt').innerHTML = '<b>' + lit + '</b> / ' + total + ' waylights' + (oil ? ' &nbsp;·&nbsp; Starlight Oil' : petals ? ' &nbsp;·&nbsp; <b>' + petals + '</b> moonpetal' + (petals > 1 ? 's' : '') : ''); };
  UI.setFlame = (v) => { $('flamefill').style.width = Math.round(v * 100) + '%'; $('flame').classList.toggle('low', v < 0.45); };
  UI.prompt = (t) => { const p = $('prompt'); if (!t || UI.talking) { p.classList.remove('on'); return; } if (p.dataset.t !== t) { p.dataset.t = t; $('ptext').textContent = t; } p.classList.add('on'); $('act').classList.add('on'); };
  UI.noPrompt = () => { $('prompt').classList.remove('on'); $('act').classList.remove('on'); };
  UI.toast = (t, secs) => { const e = $('toast'); e.textContent = t; e.classList.add('on'); toastT = secs || 4; };
  UI.card = (title, sub, secs) => { $('ctitle').textContent = title; $('csub').textContent = sub || ''; $('card').classList.add('on'); cardT = secs || 4.5; };
  UI.marker = (x, y, show, rot, edge) => { const m = $('mark'); if (!show) { m.style.display = 'none'; return; } m.style.display = 'block'; m.style.transform = 'translate(' + x.toFixed(1) + 'px,' + y.toFixed(1) + 'px) rotate(' + rot.toFixed(2) + 'rad)'; m.classList.toggle('edge', !!edge); };

  UI.say = (name, ls, done) => {
    lines = ls.slice(); li = 0; cardT = Math.min(cardT, 0.01); toastT = Math.min(toastT, 0.01); onDone = done || null; UI.talking = true; UI.noPrompt();
    $('tname').textContent = name; $('talk').classList.add('on'); show();
  };
  function show() { full = lines[li]; typeT = 0; $('ttext').textContent = ''; $('tmore').textContent = li < lines.length - 1 ? 'continue' : 'close'; }
  UI.advance = () => {
    if (!UI.talking) return;
    if (typeT * 55 < full.length) { typeT = 1e6; $('ttext').textContent = full; return; }
    HM.audio.blip(); li++;
    if (li >= lines.length) { UI.talking = false; $('talk').classList.remove('on'); const d = onDone; onDone = null; if (d) d(); } else show();
  };
  UI.update = (dt) => {
    if (UI.talking && typeT < 1e5) { typeT += dt; const n = Math.min(full.length, Math.floor(typeT * 55)); if ($('ttext').textContent.length !== n) $('ttext').textContent = full.slice(0, n); }
    if (toastT > 0) { toastT -= dt; if (toastT <= 0) $('toast').classList.remove('on'); }
    if (cardT > 0) { cardT -= dt; if (cardT <= 0) $('card').classList.remove('on'); }
  };
  UI.showTitle = (hasSave, begin, fresh) => {
    const t = $('title'); t.classList.add('on'); $('hud').classList.add('off');
    $('begin').textContent = hasSave ? 'Continue' : 'Begin'; $('fresh').style.display = hasSave ? 'inline-block' : 'none';
    const go = (fn) => (e) => { e.preventDefault(); HM.audio.start(); t.classList.remove('on'); $('hud').classList.remove('off'); fn(); };
    $('begin').onclick = go(begin); $('fresh').onclick = go(fresh);
  };
  UI.error = (m) => { const e = $('err'); e.style.display = 'block'; e.textContent = m; };
})();
