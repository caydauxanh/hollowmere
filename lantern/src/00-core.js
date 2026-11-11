/* HOLLOWMERE: LANTERNLIGHT — core: namespace, math, terrain height, input */
'use strict';
const HM = {};
(function () {
  const U = HM.U = {};
  U.clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  U.lerp = (a, b, t) => a + (b - a) * t;
  U.smooth = (a, b, v) => { const t = U.clamp((v - a) / (b - a), 0, 1); return t * t * (3 - 2 * t); };
  U.damp = (a, b, k, dt) => U.lerp(a, b, 1 - Math.exp(-k * dt));
  U.angDiff = (a, b) => { let d = (b - a) % (Math.PI * 2); if (d > Math.PI) d -= Math.PI * 2; if (d < -Math.PI) d += Math.PI * 2; return d; };
  U.rng = (seed) => { let s = seed >>> 0; return () => { s = (s + 0x6D2B79F5) >>> 0; let t = s; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; };

  /* Terrain: a few rolling sines, flattened to a plateau under the village. Same formula in GLSL (HM.GLSL_HEIGHT). */
  HM.WATER_Y = -0.34;
  HM.WORLD_R = 74;
  HM.height = (x, z) => {
    const r = Math.hypot(x, z);
    const m = U.smooth(15, 34, r);
    const h = 0.62 * Math.sin(x * 0.047 + 1.3) * Math.cos(z * 0.039 - 0.7) + 0.34 * Math.sin(x * 0.113 + z * 0.071 + 2.1) + 0.2 * Math.sin(z * 0.197 - x * 0.053) - 0.1;
    const rim = U.smooth(62, 92, r) * 5.0;        // the valley rises into the dark at its edge
    return h * m + rim + 0.06;
  };
  HM.GLSL_HEIGHT = `
float hmHeight(vec2 p){
  float r = length(p);
  float m = smoothstep(15., 34., r);
  float h = .62*sin(p.x*.047+1.3)*cos(p.y*.039-.7) + .34*sin(p.x*.113+p.y*.071+2.1) + .2*sin(p.y*.197-p.x*.053) - .1;
  float rim = smoothstep(62., 92., r) * 5.;
  return h*m + rim + .06;
}`;

  /* Input: keyboard, pointer-drag camera, touch stick. */
  const I = HM.input = { mx: 0, mz: 0, run: false, act: false, actEdge: false, yaw: 0, pitch: 0.62, zoom: 1, keys: {}, touch: false };
  const keys = I.keys;
  addEventListener('keydown', (e) => {
    if (['Space', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(e.code)) e.preventDefault();
    if (!keys[e.code] && (e.code === 'KeyE' || e.code === 'KeyF' || e.code === 'Space' || e.code === 'Enter')) I.actEdge = true;
    keys[e.code] = true;
  });
  addEventListener('keyup', (e) => { keys[e.code] = false; });
  addEventListener('blur', () => { for (const k in keys) keys[k] = false; });
  I.stick = { id: -1, ox: 0, oy: 0, x: 0, y: 0 };
  I.look = { id: -1, lx: 0, ly: 0 };
  I.poll = () => {
    let x = 0, z = 0;
    if (keys.KeyW || keys.ArrowUp) z -= 1;
    if (keys.KeyS || keys.ArrowDown) z += 1;
    if (keys.KeyA || keys.ArrowLeft) x -= 1;
    if (keys.KeyD || keys.ArrowRight) x += 1;
    let run = !!(keys.ShiftLeft || keys.ShiftRight);
    if (I.stick.id !== -1) { x = I.stick.x; z = I.stick.y; run = Math.hypot(x, z) > 0.92; }
    const l = Math.hypot(x, z);
    if (l > 1) { x /= l; z /= l; }
    I.mx = x; I.mz = z; I.run = run;
    if (keys.KeyQ) I.yaw += 0.03;
    if (keys.KeyR) I.yaw -= 0.03;
  };
  I.consumeAct = () => { const a = I.actEdge; I.actEdge = false; return a; };
})();
