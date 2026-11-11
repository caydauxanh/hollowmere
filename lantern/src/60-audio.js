/* HOLLOWMERE — sound: wind, a low drone, footsteps, the chime of a kindled lantern. All synthesised. */
(function () {
  const A = HM.audio = { on: true };
  let ctx, master, windG, droneG, noiseBuf;
  A.start = () => {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return; }
    try {
      const AC = window.AudioContext || window.webkitAudioContext; if (!AC) return;
      ctx = new AC(); master = ctx.createGain(); master.gain.value = A.on ? 0.8 : 0; master.connect(ctx.destination);
      noiseBuf = ctx.createBuffer(1, ctx.sampleRate * 2, ctx.sampleRate); const d = noiseBuf.getChannelData(0); let b = 0;
      for (let i = 0; i < d.length; i++) { const w = Math.random() * 2 - 1; b = (b + 0.02 * w) / 1.02; d[i] = b * 3.2 + w * 0.05; }
      const n = ctx.createBufferSource(); n.buffer = noiseBuf; n.loop = true;
      const f = ctx.createBiquadFilter(); f.type = 'bandpass'; f.frequency.value = 420; f.Q.value = 0.6;
      windG = ctx.createGain(); windG.gain.value = 0.22; n.connect(f); f.connect(windG); windG.connect(master); n.start();
      const lfo = ctx.createOscillator(); lfo.frequency.value = 0.09; const lg = ctx.createGain(); lg.gain.value = 180; lfo.connect(lg); lg.connect(f.frequency); lfo.start();
      droneG = ctx.createGain(); droneG.gain.value = 0.035; droneG.connect(master);
      for (const fr of [55, 82.5, 110.4]) { const o = ctx.createOscillator(); o.type = 'sine'; o.frequency.value = fr; o.connect(droneG); o.start(); }
    } catch (e) { ctx = null; }
  };
  A.setOn = (on) => { A.on = on; if (master) master.gain.setTargetAtTime(on ? 0.8 : 0, ctx.currentTime, 0.05); };
  const tone = (freq, t0, dur, vol, type) => {
    const o = ctx.createOscillator(), g = ctx.createGain(); o.type = type || 'sine'; o.frequency.value = freq;
    g.gain.setValueAtTime(0, t0); g.gain.linearRampToValueAtTime(vol, t0 + 0.012); g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g); g.connect(master); o.start(t0); o.stop(t0 + dur + 0.05);
  };
  A.chime = (big) => {
    if (!ctx) return; const t = ctx.currentTime;
    const notes = big ? [261.6, 329.6, 392, 523.3, 659.3, 784, 1046.5] : [392, 587.3, 784];
    notes.forEach((f, i) => { tone(f, t + i * (big ? 0.16 : 0.09), big ? 4.5 : 2.4, 0.11, 'sine'); tone(f * 2.01, t + i * (big ? 0.16 : 0.09), 1.2, 0.03, 'sine'); });
    const n = ctx.createBufferSource(); n.buffer = noiseBuf; const f = ctx.createBiquadFilter(); f.type = 'highpass'; f.frequency.value = 1800; const g = ctx.createGain();
    g.gain.setValueAtTime(0.5, t); g.gain.exponentialRampToValueAtTime(0.001, t + 0.5); n.connect(f); f.connect(g); g.connect(master); n.start(t); n.stop(t + 0.6);
  };
  A.step = (wet) => {
    if (!ctx) return; const t = ctx.currentTime;
    const n = ctx.createBufferSource(); n.buffer = noiseBuf; n.playbackRate.value = 0.8 + Math.random() * 0.5;
    const f = ctx.createBiquadFilter(); f.type = wet ? 'bandpass' : 'lowpass'; f.frequency.value = wet ? 1400 : 500 + Math.random() * 200; const g = ctx.createGain();
    g.gain.setValueAtTime(wet ? 0.5 : 0.34, t); g.gain.exponentialRampToValueAtTime(0.001, t + (wet ? 0.2 : 0.11)); n.connect(f); f.connect(g); g.connect(master); n.start(t, Math.random()); n.stop(t + 0.25);
  };
  A.pick = () => { if (!ctx) return; const t = ctx.currentTime; tone(880, t, 0.5, 0.08); tone(1318.5, t + 0.07, 0.7, 0.07); };
  A.blip = () => { if (!ctx) return; tone(520, ctx.currentTime, 0.12, 0.035, 'triangle'); };
  A.mood = (k, dawn) => { if (!ctx) return; windG.gain.setTargetAtTime(0.24 - k * 0.1 - dawn * 0.08, ctx.currentTime, 1); droneG.gain.setTargetAtTime(0.035 * (1 - dawn), ctx.currentTime, 1); };
})();
