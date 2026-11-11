/* HOLLOWMERE — world: sky, moon, ground, water, grass, village, waylights, colliders */
(function () {
  const W = HM.world = {};
  const U = HM.U, WATER = HM.WATER_Y;
  const NLG = 6;
  let scene, grassU, skyU, waterU, groundU, moon, hemi, fill, pool = [];
  W.colliders = { circles: [], boxes: [], segs: [] };
  W.sources = [];      // every flame in the valley: {pos, col, i, lit, kind}
  W.waylights = [];
  W.herbs = [];
  W.windows = [];
  W.dawn = 0;          // 0 = the long night, 1 = morning
  W.lit = 0;           // waylights burning (drives fog pull-back and window glow)

  W.PATHS = [
    [[3, 24], [3.5, 12], [1, 4], [0, 0]],
    [[0, 0], [2, -12], [8, -26], [13, -38], [12, -62]],
    [[0, 0], [12, 5], [26, 13], [34, 2], [41, -11]],
    [[0, 0], [-10, -10], [-19, -22], [-25, -29]],
    [[0, 0], [-14, 2], [-30, 5], [-43, 3]],
    [[0, 0], [-6, 12], [-14, 24], [-21, 35]],
  ];
  W.WAY = [
    { id: 'gate', name: 'the South Gate', x: 5.2, z: 10.5 },
    { id: 'ford', name: 'the Mill Ford', x: 27.5, z: 14.5 },
    { id: 'mill', name: 'the Old Mill', x: 42.5, z: -12.5 },
    { id: 'north', name: 'the Academy Road', x: 14.5, z: -39.5 },
    { id: 'wood', name: 'the Wood’s Edge', x: -26.5, z: -30.5, needs: 'bramble' },
    { id: 'stones', name: 'the Standing Stones', x: -44.5, z: 4.0 },
    { id: 'fen', name: 'the South Fen', x: -22.5, z: 36.5 },
  ];

  const M = {};
  const mat = (color, rough, extra) => new THREE.MeshStandardMaterial(Object.assign({ color, roughness: rough === undefined ? 0.9 : rough, metalness: 0 }, extra || {}));
  const shadow = (m, cast, recv) => { m.castShadow = cast !== false; m.receiveShadow = recv !== false; return m; };

  function segDist(px, pz, ax, az, bx, bz) {
    const abx = bx - ax, abz = bz - az; const t = U.clamp(((px - ax) * abx + (pz - az) * abz) / (abx * abx + abz * abz || 1), 0, 1);
    return Math.hypot(px - (ax + abx * t), pz - (az + abz * t));
  }
  W.pathDist = (x, z) => { let d = 1e9; for (const p of W.PATHS) for (let i = 0; i < p.length - 1; i++) d = Math.min(d, segDist(x, z, p[i][0], p[i][1], p[i + 1][0], p[i + 1][1])); return d; };

  /* ---------- sky ---------- */
  function buildSky() {
    skyU = { uTime: { value: 0 }, uDawn: { value: 0 }, uMoon: { value: new THREE.Vector3(0.35, 0.3, -0.89).normalize() } };
    const m = new THREE.ShaderMaterial({
      side: THREE.BackSide, depthWrite: false, uniforms: skyU,
      vertexShader: 'varying vec3 vD; void main(){ vD = normalize(position); vec4 p = modelViewMatrix * vec4(position, 1.); gl_Position = projectionMatrix * p; gl_Position.z = gl_Position.w * .99999; }',
      fragmentShader: `precision highp float; varying vec3 vD; uniform float uTime, uDawn; uniform vec3 uMoon;
float hash(vec3 p){ return fract(sin(dot(p, vec3(127.1,311.7,74.7))) * 43758.5453); }
float noise(vec2 p){ vec2 i = floor(p), f = fract(p); f = f*f*(3.-2.*f); float a = fract(sin(dot(i, vec2(127.1,311.7)))*43758.5453), b = fract(sin(dot(i+vec2(1,0), vec2(127.1,311.7)))*43758.5453), c = fract(sin(dot(i+vec2(0,1), vec2(127.1,311.7)))*43758.5453), d = fract(sin(dot(i+vec2(1,1), vec2(127.1,311.7)))*43758.5453); return mix(mix(a,b,f.x), mix(c,d,f.x), f.y); }
float fbm(vec2 p){ float s = 0., a = .5; for (int i = 0; i < 4; i++){ s += a*noise(p); p = p*2.03 + 7.1; a *= .5; } return s; }
void main(){
  vec3 d = normalize(vD); float up = max(d.y, 0.);
  vec3 night = mix(vec3(.016,.028,.05), vec3(.003,.006,.016), pow(up, .55));
  vec3 dawnc = mix(vec3(1.5,.62,.26), vec3(.16,.3,.62), pow(up, .5));
  dawnc += vec3(1.6,.7,.25) * pow(max(dot(d, normalize(vec3(.9,.06,.42))), 0.), 6.);
  vec3 col = mix(night, dawnc, uDawn);
  // stars
  vec3 g = floor(d * 190.); float h = hash(g);
  float star = step(.9965, h) * (.4 + .6*sin(uTime*2. + h*90.)) * smoothstep(.02, .3, d.y);
  col += vec3(.9,.95,1.) * star * 1.6 * (1. - uDawn);
  // moon
  float md = dot(d, uMoon);
  col += vec3(.75,.85,1.) * (smoothstep(.9994, .9997, md) * 9. + pow(max(md, 0.), 900.) * 1.5 + pow(max(md, 0.), 24.) * .11) * (1. - uDawn*.9);
  // drifting cloud
  vec2 cp = d.xz / (d.y + .28) * 1.6 + vec2(uTime*.006, uTime*.003);
  float c = smoothstep(.46, .82, fbm(cp)) * smoothstep(-.02, .22, d.y);
  vec3 cc = mix(vec3(.02,.03,.05) + vec3(.2,.25,.35)*pow(max(md,0.), 6.), vec3(1.1,.6,.4), uDawn);
  col = mix(col, cc, c * .75);
  gl_FragColor = vec4(col, 1.);
}` });
    const s = new THREE.Mesh(new THREE.SphereGeometry(380, 32, 16), m); s.frustumCulled = false; s.renderOrder = -10; scene.add(s); W.sky = s;
  }

  /* ---------- ground + water ---------- */
  function paintGround() {
    const N = 512, c = document.createElement('canvas'); c.width = c.height = N; const g = c.getContext('2d');
    const img = g.createImageData(N, N), d = img.data, r = U.rng(5);
    const n2 = (x, z) => 0.5 + 0.25 * Math.sin(x * 0.31 + Math.sin(z * 0.23) * 2.0) + 0.25 * Math.sin(z * 0.41 + Math.sin(x * 0.17) * 2.3);
    for (let j = 0; j < N; j++) for (let i = 0; i < N; i++) {
      const x = (i + 0.5) / N * 220 - 110, z = (j + 0.5) / N * 220 - 110, h = HM.height(x, z);
      const n = n2(x, z), wet = U.smooth(WATER + 0.34, WATER + 0.02, h), rr = Math.hypot(x, z), dry = U.smooth(0.2, 0.75, h) * n * (1 - U.smooth(46, 64, rr)), far = 1 - U.smooth(58, 80, rr) * 0.6;
      let R = U.lerp(0.19, 0.30, n), Gc = U.lerp(0.24, 0.33, n), B = U.lerp(0.10, 0.13, n);          // turf
      R = U.lerp(R, 0.42, dry * 0.7); Gc = U.lerp(Gc, 0.37, dry * 0.7); B = U.lerp(B, 0.19, dry * 0.7);   // dry heath
      R = U.lerp(R, 0.12, wet); Gc = U.lerp(Gc, 0.10, wet); B = U.lerp(B, 0.075, wet);                 // mud
      const k = (j * N + i) * 4, gr = (0.93 + r() * 0.14) * far;
      d[k] = Math.pow(R * gr * 0.36, 0.4545) * 255; d[k + 1] = Math.pow(Gc * gr * 0.36, 0.4545) * 255; d[k + 2] = Math.pow(B * gr * 0.36, 0.4545) * 255; d[k + 3] = 255;
    }
    g.putImageData(img, 0, 0);
    const P = (v) => (v + 110) / 220 * N;
    g.lineCap = g.lineJoin = 'round';
    for (const pass of [[9, 'rgba(96,80,60,0.55)', 6], [5, 'rgba(128,110,86,0.8)', 2]]) {
      g.lineWidth = pass[0]; g.strokeStyle = pass[1]; g.shadowColor = pass[1]; g.shadowBlur = pass[2];
      for (const p of W.PATHS) { g.beginPath(); g.moveTo(P(p[0][0]), P(p[0][1])); for (let i = 1; i < p.length; i++) g.lineTo(P(p[i][0]), P(p[i][1])); g.stroke(); }
    }
    g.shadowBlur = 8; g.fillStyle = 'rgba(124,116,102,0.9)'; g.shadowColor = 'rgba(100,92,80,0.9)'; g.beginPath(); g.arc(P(0), P(0), 5.6 / 220 * N, 0, 7); g.fill();
    const t = new THREE.CanvasTexture(c); t.colorSpace = THREE.SRGBColorSpace; t.anisotropy = 4; return t;
  }
  function paintMask() {   // white = grass may grow
    const N = 256, c = document.createElement('canvas'); c.width = c.height = N; const g = c.getContext('2d');
    g.fillStyle = '#fff'; g.fillRect(0, 0, N, N);
    const P = (v) => (v + 110) / 220 * N;
    g.strokeStyle = '#000'; g.lineCap = g.lineJoin = 'round'; g.lineWidth = 3.4; g.shadowColor = '#000'; g.shadowBlur = 2;
    for (const p of W.PATHS) { g.beginPath(); g.moveTo(P(p[0][0]), P(p[0][1])); for (let i = 1; i < p.length; i++) g.lineTo(P(p[i][0]), P(p[i][1])); g.stroke(); }
    g.fillStyle = '#000'; g.beginPath(); g.arc(P(0), P(0), 7.2 / 220 * N, 0, 7); g.fill();
    for (const b of W.colliders.boxes) { g.beginPath(); g.arc(P(b.x), P(b.z), (Math.max(b.hw, b.hd) + 0.9) / 220 * N, 0, 7); g.fill(); }
    const t = new THREE.CanvasTexture(c); t.minFilter = t.magFilter = THREE.LinearFilter; t.generateMipmaps = false; W.maskCanvas = c; return t;
  }
  function buildGround() {
    const geo = new THREE.PlaneGeometry(220, 220, 180, 180); geo.rotateX(-Math.PI / 2);
    const p = geo.attributes.position;
    for (let i = 0; i < p.count; i++) p.setY(i, HM.height(p.getX(i), p.getZ(i)));
    geo.computeVertexNormals();
    groundU = { uT: { value: 0 } };
    const m = mat(0xffffff, 0.96, { map: paintGround() });
    m.onBeforeCompile = (sh) => {
      sh.vertexShader = sh.vertexShader.replace('#include <common>', '#include <common>\nvarying vec3 vWp;').replace('#include <worldpos_vertex>', '#include <worldpos_vertex>\nvWp = (modelMatrix * vec4(transformed, 1.)).xyz;');
      sh.fragmentShader = sh.fragmentShader.replace('#include <common>', '#include <common>\nvarying vec3 vWp;\nfloat gh(vec2 p){ return fract(sin(dot(p, vec2(41.3,289.1))) * 45758.5453); }\nfloat gn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f*f*(3.-2.*f); return mix(mix(gh(i), gh(i+vec2(1,0)), f.x), mix(gh(i+vec2(0,1)), gh(i+vec2(1,1)), f.x), f.y); }')
        .replace('#include <map_fragment>', `#include <map_fragment>
  float gdet = gn(vWp.xz * 2.3) * .6 + gn(vWp.xz * 9.1) * .4;
  diffuseColor.rgb *= .72 + gdet * .56;
  float gwet = smoothstep(${(WATER + 0.3).toFixed(2)}, ${(WATER + 0.03).toFixed(2)}, vWp.y);
  diffuseColor.rgb *= 1. - gwet * .45;`)
        .replace('#include <roughnessmap_fragment>', `#include <roughnessmap_fragment>\n  roughnessFactor = mix(roughnessFactor, .34, gwet * (.5 + .5*gdet));`);
    };
    const g = new THREE.Mesh(geo, m); g.receiveShadow = true; scene.add(g);
    // water: a dark mirror lying in every hollow
    waterU = { uT: { value: 0 } };
    const wm = mat(0x06090d, 0.11, { metalness: 0.0, transparent: true, opacity: 0.9 });
    wm.onBeforeCompile = (sh) => {
      sh.uniforms.uT = waterU.uT;
      sh.vertexShader = sh.vertexShader.replace('#include <common>', '#include <common>\nvarying vec3 vWp;').replace('#include <worldpos_vertex>', '#include <worldpos_vertex>\nvWp = (modelMatrix * vec4(transformed, 1.)).xyz;');
      sh.fragmentShader = sh.fragmentShader.replace('#include <common>', '#include <common>\nvarying vec3 vWp; uniform float uT;')
        .replace('#include <normal_fragment_begin>', '#include <normal_fragment_begin>\n  normal = normalize(normal + vec3(sin(vWp.x*2.9 + uT*1.1) * .035 + sin(vWp.z*6.7 - uT*1.7) * .02, 0., cos(vWp.z*2.3 + uT*.9) * .035 + sin(vWp.x*5.9 + uT*1.3) * .02));');
    };
    const wg = new THREE.PlaneGeometry(220, 220, 1, 1); wg.rotateX(-Math.PI / 2);
    const w = new THREE.Mesh(wg, wm); w.position.y = WATER; w.receiveShadow = true; scene.add(w);
  }

  /* ---------- grass ---------- */
  function buildGrass(count) {
    const T = 44;
    const geo = new THREE.InstancedBufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(new Float32Array([-0.5, 0, 0, 0.5, 0, 0, -0.36, 0.5, 0.06, 0.36, 0.5, 0.06, 0, 1, 0.2]), 3));
    geo.setIndex([0, 1, 2, 1, 3, 2, 2, 3, 4]);
    const off = new Float32Array(count * 4), r = U.rng(11);
    for (let i = 0; i < count; i++) { off[i * 4] = r() * T; off[i * 4 + 1] = r() * T; off[i * 4 + 2] = r(); off[i * 4 + 3] = r(); }
    geo.setAttribute('aOff', new THREE.InstancedBufferAttribute(off, 4));
    geo.instanceCount = count;
    grassU = {
      uCenter: { value: new THREE.Vector3() }, uPlayer: { value: new THREE.Vector3() }, uTime: { value: 0 }, uTile: { value: T }, tMask: { value: paintMask() },
      uMoonDir: { value: new THREE.Vector3() }, uMoonCol: { value: new THREE.Vector3() }, uHemiSky: { value: new THREE.Vector3() }, uHemiGnd: { value: new THREE.Vector3() },
      uLP: { value: Array.from({ length: NLG }, () => new THREE.Vector3()) }, uLC: { value: Array.from({ length: NLG }, () => new THREE.Vector3()) }, uLR: { value: new Float32Array(NLG) },
    };
    const m = new THREE.ShaderMaterial({
      side: THREE.DoubleSide, uniforms: grassU,
      vertexShader: `precision highp float;
attribute vec4 aOff; uniform vec3 uCenter, uPlayer, uMoonDir, uMoonCol, uHemiSky, uHemiGnd; uniform float uTime, uTile; uniform sampler2D tMask;
uniform vec3 uLP[${NLG}]; uniform vec3 uLC[${NLG}]; uniform float uLR[${NLG}];
varying vec3 vCol;
${HM.GLSL_HEIGHT}
void main(){
  vec2 rel = mod(aOff.xy - uCenter.xz + uTile*.5, uTile) - uTile*.5;
  vec2 root = uCenter.xz + rel;
  float y = hmHeight(root);
  float mask = texture2D(tMask, root/220. + .5).r * smoothstep(${(WATER + 0.02).toFixed(2)}, ${(WATER + 0.2).toFixed(2)}, y) * (1. - smoothstep(uTile*.36, uTile*.5, length(rel)));
  float tall = step(.93, aOff.w);
  float hgt = mix(.2, .46, aOff.z) + tall * .42; float wid = mix(.022, .045, aOff.w) * (1. + tall*.3);
  float a = aOff.z * 37.7; float ca = cos(a), sa = sin(a);
  vec3 lp = vec3(position.x * wid, position.y * hgt, position.z * hgt);
  lp.xz = vec2(lp.x*ca - lp.z*sa, lp.x*sa + lp.z*ca);
  float hh = position.y;
  float w = sin(uTime*1.3 + root.x*.29 + root.y*.21) * .16 + sin(uTime*3.1 + root.x*1.1 + aOff.z*6.) * .05;
  lp.x += w * hh*hh * hgt; lp.z += w * .55 * hh*hh * hgt;
  vec2 pd = root - uPlayer.xz; float pk = 1. - smoothstep(.25, 1.2, length(pd));
  lp.xz += normalize(pd + vec2(.0001)) * pk * .4 * hh; lp.y *= 1. - pk * .6;
  vec3 wp = vec3(root.x, y, root.y) + lp * mask;
  vec3 n = normalize(vec3(lp.x*.5, 1., lp.z*.5));
  vec3 base = mix(vec3(.035,.06,.018), vec3(.11,.15,.045), aOff.w);
  vec3 tip = mix(vec3(.12,.24,.07), vec3(.25,.29,.11), smoothstep(.55, 1., aOff.z));
  vec3 alb = mix(base, tip, hh);
  vec3 E = mix(uHemiGnd, uHemiSky, n.y*.5 + .5);
  E += uMoonCol * (max(dot(n, uMoonDir), 0.) * .5 + .12);
  for (int i = 0; i < ${NLG}; i++){
    vec3 L = uLP[i] - wp; float d = length(L);
    float f = 1. / max(pow(d, 1.25), .01); float c = clamp(1. - pow(d / uLR[i], 4.), 0., 1.); f *= c*c;
    float nd = max(dot(n, L/d), 0.) * .55 + .45;          // blades take light from every side
    E += uLC[i] * f * nd * (.45 + .65*hh);
  }
  vCol = alb * E * .3183;
  gl_Position = projectionMatrix * viewMatrix * vec4(wp, 1.);
}`,
      fragmentShader: 'precision highp float; varying vec3 vCol; void main(){ gl_FragColor = vec4(vCol, 1.); }',
    });
    const g = new THREE.Mesh(geo, m); g.frustumCulled = false; scene.add(g); W.grass = g;
  }

  /* ---------- prop builders ---------- */
  function grit(m, sc, amt) {
    m.onBeforeCompile = (sh) => {
      sh.vertexShader = sh.vertexShader.replace('#include <common>', '#include <common>\nvarying vec3 vWp;').replace('#include <worldpos_vertex>', '#include <worldpos_vertex>\nvWp = (modelMatrix * vec4(transformed, 1.)).xyz;\n#ifdef USE_INSTANCING\nvWp = (modelMatrix * instanceMatrix * vec4(transformed, 1.)).xyz;\n#endif');
      sh.fragmentShader = sh.fragmentShader.replace('#include <common>', '#include <common>\nvarying vec3 vWp;\nfloat gh(vec3 p){ return fract(sin(dot(p, vec3(41.3,289.1,97.7))) * 45758.5453); }\nfloat gn(vec3 p){ vec3 i = floor(p), f = fract(p); f = f*f*(3.-2.*f); return mix(mix(mix(gh(i), gh(i+vec3(1,0,0)), f.x), mix(gh(i+vec3(0,1,0)), gh(i+vec3(1,1,0)), f.x), f.y), mix(mix(gh(i+vec3(0,0,1)), gh(i+vec3(1,0,1)), f.x), mix(gh(i+vec3(0,1,1)), gh(i+vec3(1,1,1)), f.x), f.y), f.z); }')
        .replace('#include <map_fragment>', '#include <map_fragment>\n  float gd = gn(vWp * ' + sc.toFixed(1) + ') * .55 + gn(vWp * ' + (sc * 4.3).toFixed(1) + ') * .3 + gn(vWp * ' + (sc * 0.22).toFixed(2) + ') * .35;\n  diffuseColor.rgb *= ' + (1 - amt * 0.6).toFixed(2) + ' + gd * ' + amt.toFixed(2) + ';');
    };
    return m;
  }
  function initMats() {
    M.stone = mat(0x77736a, 0.95, { flatShading: true }); M.stoneD = mat(0x4b4944, 0.95, { flatShading: true });
    M.wood = mat(0x3d2e22, 0.9); M.woodL = mat(0x5b4633, 0.9); M.bark = mat(0x221b17, 1.0, { flatShading: true });
    M.thatch = mat(0x6a5632, 1.0, { flatShading: true }); M.slate = mat(0x2b3038, 0.8, { flatShading: true });
    M.plaster = grit(mat(0x9a917e, 0.95), 2.2, 0.7); grit(M.stone, 3, 0.8); grit(M.stoneD, 3, 0.8); grit(M.thatch, 5, 0.9); grit(M.slate, 4, 0.8); grit(M.wood, 6, 0.7); grit(M.woodL, 6, 0.7); M.iron = mat(0x16171a, 0.6, { metalness: 0.6 });
    M.pine = mat(0x0f2014, 1.0, { flatShading: true });
    M.glassOff = mat(0x20242a, 0.3);
  }
  const glow = (hex, i) => new THREE.MeshStandardMaterial({ color: 0x110a04, emissive: hex, emissiveIntensity: i, roughness: 0.6 });

  function cottage(x, z, rot, w, d, roofMat) {
    const g = new THREE.Group(); g.position.set(x, HM.height(x, z) - 0.05, z); g.rotation.y = rot;
    const h = 2.5;
    const walls = shadow(new THREE.Mesh(new THREE.BoxGeometry(w, h, d), M.plaster)); walls.position.y = h / 2; g.add(walls);
    const base = shadow(new THREE.Mesh(new THREE.BoxGeometry(w + 0.16, 0.7, d + 0.16), M.stone)); base.position.y = 0.35; g.add(base);
    const pitch = 0.82, sl = (d / 2 + 0.45) / Math.cos(pitch);
    for (const s of [-1, 1]) {
      const slab = shadow(new THREE.Mesh(new THREE.BoxGeometry(w + 0.8, 0.2, sl), roofMat));
      slab.position.set(0, h + Math.sin(pitch) * sl / 2 - 0.12, s * (Math.cos(pitch) * sl / 2 - 0.02)); slab.rotation.x = s * pitch; g.add(slab);
    }
    const gh = Math.tan(pitch) * d / 2;
    const tri = new THREE.Shape(); tri.moveTo(-d / 2, 0); tri.lineTo(d / 2, 0); tri.lineTo(0, gh); tri.closePath();
    for (const s of [-1, 1]) { const gb = shadow(new THREE.Mesh(new THREE.ShapeGeometry(tri), M.plaster)); gb.rotation.y = s * Math.PI / 2; gb.position.set(s * (w / 2 - 0.001), h, 0); g.add(gb); }
    const beam = (bw, bh, bd, bx, by, bz, rz) => { const b = new THREE.Mesh(new THREE.BoxGeometry(bw, bh, bd), M.wood); b.position.set(bx, by, bz); if (rz) b.rotation.z = rz; g.add(b); };
    for (const sx of [-1, 1]) for (const sz of [-1, 1]) beam(0.2, h - 0.6, 0.2, sx * (w / 2 - 0.02), h / 2 + 0.33, sz * (d / 2 - 0.02));
    for (const sz of [-1, 1]) { beam(w + 0.1, 0.18, 0.14, 0, h - 0.06, sz * (d / 2 + 0.0)); beam(w, 0.13, 0.1, 0, 0.78, sz * (d / 2 + 0.01)); beam(0.13, h - 0.8, 0.1, w * 0.06, h / 2 + 0.33, sz * (d / 2 + 0.01)); }
    beam(0.11, 1.5, 0.09, w * 0.44 - 0.45, 1.2, d / 2 + 0.01, 0.62); beam(0.11, 1.5, 0.09, -w * 0.44 + 0.2, 2.0, -d / 2 - 0.01, -0.5);
    for (const sx of [-1, 1]) { const gb2 = new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.15, d + 0.1), M.wood); gb2.position.set(sx * (w / 2 + 0.01), h - 0.06, 0); g.add(gb2); const kp = new THREE.Mesh(new THREE.BoxGeometry(0.1, gh - 0.1, 0.13), M.wood); kp.position.set(sx * (w / 2 + 0.01), h + gh / 2 - 0.08, 0); g.add(kp); }
    const ch = shadow(new THREE.Mesh(new THREE.BoxGeometry(0.6, 1.9, 0.6), M.stone)); ch.position.set(w * 0.28, h + gh * 0.75, -d * 0.12); g.add(ch);
    const door = new THREE.Mesh(new THREE.BoxGeometry(0.95, 1.85, 0.1), M.wood); door.position.set(-w * 0.18, 0.95, d / 2 + 0.03); g.add(door);
    const wm = glow(0xff9a3c, 1.4); W.windows.push(wm);
    for (const wx of [w * 0.24, -w * 0.4]) {
      const win = new THREE.Mesh(new THREE.BoxGeometry(0.7, 0.78, 0.08), wm); win.position.set(wx, 1.55, d / 2 + 0.02); g.add(win);
      for (const b of [[0.82, 0.07, 0, 0.42], [0.82, 0.07, 0, -0.42], [0.07, 0.86, 0.4, 0], [0.07, 0.86, -0.4, 0], [0.05, 0.8, 0, 0]]) { const fr = new THREE.Mesh(new THREE.BoxGeometry(b[0], b[1], 0.12), M.wood); fr.position.set(wx + b[2], 1.55 + b[3], d / 2 + 0.04); g.add(fr); }
    }
    const sw = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.7, 0.62), wm); sw.position.set(w / 2 + 0.02, 1.55, 0.2); g.add(sw);
    scene.add(g);
    W.colliders.boxes.push({ x, z, hw: w / 2 + 0.25, hd: d / 2 + 0.25, c: Math.cos(rot), s: Math.sin(rot) });
    return g;
  }

  function branch(parent, len, rad, depth, r) {
    const geo = new THREE.CylinderGeometry(rad * 0.55, rad, len, 6, 1); geo.translate(0, len / 2, 0);
    const b = shadow(new THREE.Mesh(geo, M.bark), true, false); parent.add(b);
    if (depth > 0) {
      const n = 2 + (r() < 0.5 ? 1 : 0);
      for (let i = 0; i < n; i++) {
        const j = new THREE.Group(); j.position.y = len * (0.55 + r() * 0.45); j.rotation.set((r() - 0.5) * 0.5, r() * 6.28, 0.45 + r() * 0.7);
        b.add(j); branch(j, len * (0.5 + r() * 0.25), rad * 0.55, depth - 1, r);
      }
    }
    return b;
  }
  function deadTree(x, z, s, r) {
    const g = new THREE.Group(); g.position.set(x, HM.height(x, z) - 0.1, z); g.rotation.set((r() - 0.5) * 0.12, r() * 6.28, (r() - 0.5) * 0.12); g.scale.setScalar(s);
    branch(g, 2.6 + r() * 1.2, 0.2, 3, r); scene.add(g);
    W.colliders.circles.push({ x, z, r: 0.34 * s });
  }
  function pine(x, z, s, r) {
    const g = new THREE.Group(); g.position.set(x, HM.height(x, z) - 0.1, z); g.rotation.y = r() * 6.28; g.scale.setScalar(s);
    const tr = shadow(new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.2, 2.2, 6), M.bark), true, false); tr.position.y = 1.1; g.add(tr);
    for (let i = 0; i < 5; i++) { const c = shadow(new THREE.Mesh(new THREE.ConeGeometry(1.5 - i * 0.26, 1.7, 7), M.pine), true, false); c.position.y = 1.7 + i * 0.95; c.rotation.y = i * 0.7; g.add(c); }
    scene.add(g); W.colliders.circles.push({ x, z, r: 0.3 * s });
  }
  function rock(x, z, s, r, tall) {
    const geo = new THREE.IcosahedronGeometry(1, 1), p = geo.attributes.position;
    for (let i = 0; i < p.count; i++) { const k = 0.78 + r() * 0.4; p.setXYZ(i, p.getX(i) * k, p.getY(i) * k, p.getZ(i) * k); }
    geo.computeVertexNormals();
    const m = shadow(new THREE.Mesh(geo, r() < 0.5 ? M.stone : M.stoneD)); m.position.set(x, HM.height(x, z) + (tall ? s * 1.1 : s * 0.25), z);
    m.scale.set(s * (tall ? 0.55 : 1), s * (tall ? 1.7 : 0.62), s * (tall ? 0.42 : 0.85)); m.rotation.set(tall ? (r() - 0.5) * 0.2 : r(), r() * 6.28, tall ? (r() - 0.5) * 0.2 : r());
    scene.add(m); if (s > 0.45) W.colliders.circles.push({ x, z, r: s * (tall ? 0.55 : 0.85) });
  }
  const wallStones = [], fencePosts = [];
  function stoneWall(ax, az, bx, bz, r) {
    const len = Math.hypot(bx - ax, bz - az), n = Math.floor(len / 0.4), ang = Math.atan2(bx - ax, bz - az);
    for (let i = 0; i <= n; i++) for (let c = 0; c < 3; c++) {
      const t = (i + (c % 2 ? 0.5 : 0) + (r() - 0.5) * 0.3) / n; if (t > 1 || t < 0 || (c === 2 && r() < 0.3)) continue;
      const x = U.lerp(ax, bx, t) + (r() - 0.5) * 0.12, z = U.lerp(az, bz, t) + (r() - 0.5) * 0.12;
      wallStones.push({ x, y: HM.height(x, z) + 0.13 + c * 0.27, z, ry: ang + (r() - 0.5) * 0.7, sx: 0.3 + r() * 0.14, sy: 0.2 + r() * 0.09, sz: 0.27 + r() * 0.2 });
    }
    W.colliders.segs.push({ ax, az, bx, bz, r: 0.42 });
  }
  function fence(ax, az, bx, bz, r) {
    const len = Math.hypot(bx - ax, bz - az), n = Math.max(1, Math.round(len / 2.3)), ang = Math.atan2(bx - ax, bz - az);
    let prev = null;
    for (let i = 0; i <= n; i++) {
      const t = i / n, x = U.lerp(ax, bx, t), z = U.lerp(az, bz, t), y = HM.height(x, z);
      fencePosts.push({ x, y: y + 0.55, z, ry: r() * 3, tilt: (r() - 0.5) * 0.14 });
      if (prev && r() > 0.12) for (const hh of [0.42, 0.86]) {
        const rail = shadow(new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.09, Math.hypot(x - prev.x, z - prev.z) + 0.1), M.woodL), true, false);
        rail.position.set((x + prev.x) / 2, (y + prev.y) / 2 + hh, (z + prev.z) / 2); rail.rotation.y = ang; rail.rotation.x = -Math.atan2(y - prev.y, Math.hypot(x - prev.x, z - prev.z)) + (r() - 0.5) * 0.05; scene.add(rail);
      }
      prev = { x, y, z };
    }
    W.colliders.segs.push({ ax, az, bx, bz, r: 0.22 });
  }
  function flushInstances() {
    const dm = new THREE.Object3D();
    const ws = new THREE.InstancedMesh(new THREE.DodecahedronGeometry(0.72, 0), M.stone, wallStones.length); ws.castShadow = ws.receiveShadow = true;
    wallStones.forEach((s, i) => { dm.position.set(s.x, s.y, s.z); dm.rotation.set((i % 7) * 0.03 - 0.1, s.ry, (i % 5) * 0.04 - 0.08); dm.scale.set(s.sx, s.sy, s.sz); dm.updateMatrix(); ws.setMatrixAt(i, dm.matrix); });
    scene.add(ws);
    const fp = new THREE.InstancedMesh(new THREE.CylinderGeometry(0.055, 0.07, 1.2, 6), M.woodL, fencePosts.length); fp.castShadow = true;
    fencePosts.forEach((s, i) => { dm.position.set(s.x, s.y, s.z); dm.rotation.set(s.tilt, s.ry, s.tilt * 0.7); dm.scale.set(1, 1, 1); dm.updateMatrix(); fp.setMatrixAt(i, dm.matrix); });
    scene.add(fp);
  }

  function lanternBox(lit) {
    const g = new THREE.Group();
    const glass = new THREE.Mesh(new THREE.BoxGeometry(0.2, 0.28, 0.2), glow(0xffa040, 0)); g.add(glass);
    const cap = new THREE.Mesh(new THREE.ConeGeometry(0.2, 0.14, 4), M.iron); cap.position.y = 0.21; cap.rotation.y = Math.PI / 4; g.add(cap);
    const bot = new THREE.Mesh(new THREE.BoxGeometry(0.24, 0.04, 0.24), M.iron); bot.position.y = -0.16; g.add(bot);
    for (const [ex, ez] of [[1, 1], [1, -1], [-1, 1], [-1, -1]]) { const bar = new THREE.Mesh(new THREE.BoxGeometry(0.025, 0.3, 0.025), M.iron); bar.position.set(ex * 0.105, 0, ez * 0.105); g.add(bar); }
    g.userData.glass = glass; if (lit) glass.material.emissiveIntensity = 9;
    return g;
  }
  HM.lanternBox = lanternBox;

  function waylight(def) {
    const x = def.x, z = def.z, y = HM.height(x, z);
    const g = new THREE.Group(); g.position.set(x, y, z); g.rotation.y = Math.atan2(-x, -z) + 0.6;
    const post = shadow(new THREE.Mesh(new THREE.CylinderGeometry(0.075, 0.11, 3.3, 7), M.wood), true, false); post.position.y = 1.65; g.add(post);
    const arm = shadow(new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.09, 0.09), M.wood), true, false); arm.position.set(0.36, 3.05, 0); g.add(arm);
    const brace = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.06, 0.06), M.wood); brace.position.set(0.24, 2.78, 0); brace.rotation.z = 0.75; g.add(brace);
    const chain = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 0.28, 4), M.iron); chain.position.set(0.72, 2.87, 0); g.add(chain);
    const lb = lanternBox(false); lb.position.set(0.72, 2.56, 0); g.add(lb);
    for (let i = 0; i < 3; i++) { const st = new THREE.Mesh(new THREE.IcosahedronGeometry(0.2, 0), M.stoneD); st.position.set(Math.cos(i * 2.1) * 0.22, 0.08, Math.sin(i * 2.1) * 0.22); st.scale.y = 0.6; g.add(st); }
    scene.add(g); g.updateMatrixWorld(true);
    const lp = new THREE.Vector3(); lb.getWorldPosition(lp);
    const src = { pos: lp, col: new THREE.Color(1.0, 0.62, 0.3), i: 0, target: 0, lit: false, kind: 'way', range: 22 };
    W.sources.push(src);
    W.colliders.circles.push({ x, z, r: 0.28 });
    const w = { def, group: g, glass: lb.userData.glass, src, lit: false, x, z };
    w.setLit = (on, instant) => { w.lit = on; src.lit = on; src.target = on ? 34 : 0; if (instant) src.i = src.target; };
    W.waylights.push(w); return w;
  }

  function buildVillage(r) {
    cottage(-11.5, -6.5, 1.25, 5.6, 4.4, M.thatch);
    cottage(11, -8.5, -1.05, 6.2, 4.6, M.slate);
    cottage(13.5, 7, -2.1, 5.2, 4.2, M.thatch);
    cottage(-10, 10.5, 2.35, 5.4, 4.4, M.thatch);
    W.apothecary = cottage(-3.5, -15.5, 0.2, 6.4, 4.8, M.slate);
    // shrine: three worn steps, a pillar, the Great Lantern
    const sg = new THREE.Group();
    [[3.4, 0.24, 0.12], [2.5, 0.24, 0.36], [1.6, 0.26, 0.61]].forEach(([rad, h, y]) => { const st = shadow(new THREE.Mesh(new THREE.CylinderGeometry(rad, rad + 0.08, h, 10), M.stone)); st.position.y = y; sg.add(st); });
    const pil = shadow(new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.34, 2.2, 8), M.stoneD)); pil.position.y = 1.84; sg.add(pil);
    const capst = shadow(new THREE.Mesh(new THREE.CylinderGeometry(0.5, 0.3, 0.22, 8), M.stone)); capst.position.y = 3.05; sg.add(capst);
    const gl = lanternBox(false); gl.scale.setScalar(2.6); gl.position.y = 3.62; sg.add(gl);
    const candle = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.04, 0.2, 6), mat(0xd8cfb8, 0.7)); candle.position.set(0.9, 0.84, 0.5); sg.add(candle);
    const flame = new THREE.Mesh(new THREE.SphereGeometry(0.035, 6, 5), glow(0xffb050, 14)); flame.position.set(0.9, 0.98, 0.5); flame.scale.y = 1.7; sg.add(flame);
    scene.add(sg);
    W.colliders.circles.push({ x: 0, z: 0, r: 1.95 });
    W.sources.push({ pos: new THREE.Vector3(0.9, 1.05, 0.5), col: new THREE.Color(1.0, 0.7, 0.35), i: 3.5, target: 3.5, lit: true, kind: 'candle', range: 9 });
    W.great = { glass: gl.userData.glass, src: { pos: new THREE.Vector3(0, 3.62, 0), col: new THREE.Color(1.0, 0.72, 0.4), i: 0, target: 0, lit: false, kind: 'great', range: 40 }, lit: false, x: 0, z: 0 };
    W.sources.push(W.great.src);
    W.great.setLit = (on, instant) => { W.great.lit = on; W.great.src.lit = on; W.great.src.target = on ? 55 : 0; if (instant) W.great.src.i = W.great.src.target; };
    // apothecary yard: cauldron over a small fire, herb beds
    const cx = -0.6, cz = -11.6;
    const cg = new THREE.Group(); cg.position.set(cx, HM.height(cx, cz), cz);
    const pot = shadow(new THREE.Mesh(new THREE.SphereGeometry(0.46, 12, 8, 0, 6.3, 0.5, 2.3), M.iron)); pot.position.y = 0.62; cg.add(pot);
    const brew = new THREE.Mesh(new THREE.CircleGeometry(0.38, 12), glow(0x3cffb0, 1.2)); brew.rotation.x = -Math.PI / 2; brew.position.y = 0.8; cg.add(brew); W.brew = brew;
    for (let i = 0; i < 3; i++) { const leg = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.03, 0.5, 5), M.iron); leg.position.set(Math.cos(i * 2.09) * 0.32, 0.22, Math.sin(i * 2.09) * 0.32); cg.add(leg); }
    const fire = new THREE.Mesh(new THREE.ConeGeometry(0.2, 0.3, 6), glow(0xff6a20, 7)); fire.position.y = 0.16; cg.add(fire); W.fire = fire;
    scene.add(cg);
    W.colliders.circles.push({ x: cx, z: cz, r: 0.62 });
    W.cauldron = { x: cx, z: cz };
    W.sources.push({ pos: new THREE.Vector3(cx, 0.45, cz), col: new THREE.Color(1.0, 0.45, 0.18), i: 5, target: 5, lit: true, kind: 'fire', range: 8 });
    for (let i = 0; i < 3; i++) { const bed = shadow(new THREE.Mesh(new THREE.BoxGeometry(1.7, 0.22, 0.9), M.wood)); bed.position.set(-6.2 + i * 2.1, 0.1, -11.4); scene.add(bed); const soil = new THREE.Mesh(new THREE.BoxGeometry(1.56, 0.06, 0.76), mat(0x1c1611, 1)); soil.position.set(-6.2 + i * 2.1, 0.2, -11.4); scene.add(soil); W.colliders.boxes.push({ x: -6.2 + i * 2.1, z: -11.4, hw: 0.9, hd: 0.5, c: 1, s: 0 }); }
    // walls and fences along the lanes
    stoneWall(-4, 16, -13, 15.5, r); stoneWall(8.5, 15, 17, 13.5, r); stoneWall(17, 13.5, 20.5, 6, r); stoneWall(-17, 6, -18.5, -3, r); stoneWall(5, -19, 15, -16.5, r); stoneWall(-13, -14, -9.5, -19.5, r);
    fence(16, 16.5, 23.5, 16.5, r); fence(30.5, 9, 36.5, 1, r); fence(-21, 9, -34, 9.5, r); fence(-9, 20, -15, 29, r); fence(4.5, -27, 9, -36, r); fence(18, -41, 16.5, -52, r); fence(-14, -18, -21, -27, r);
    // standing stones on the west moor
    for (let i = 0; i < 7; i++) { const a = i / 7 * 6.283 + 0.3; rock(-44.5 + Math.cos(a) * 5.2, 4 + Math.sin(a) * 5.2, 0.9 + r() * 0.45, r, true); }
    // the old mill: a roofless stone ring by the east water
    for (let i = 0; i < 9; i++) { const a = i / 9 * 6.283; if (i === 2) continue; stoneWall(45.5 + Math.cos(a) * 3.6, -16 + Math.sin(a) * 3.6, 45.5 + Math.cos(a + 0.7) * 3.6, -16 + Math.sin(a + 0.7) * 3.6, r); }
  }

  function buildWilds(r) {
    // the Thornwood, north-west: bare trees thickening into pine
    for (let i = 0; i < 70; i++) {
      const x = -52 + r() * 40, z = -62 + r() * 44;
      if (W.pathDist(x, z) < 2.6 || Math.hypot(x + 26.5, z + 30.5) < 3.2 || HM.height(x, z) < WATER + 0.12) continue;
      (r() < 0.42 ? pine : deadTree)(x, z, 0.9 + r() * 0.7, r);
    }
    for (let i = 0; i < 46; i++) {
      const a = r() * 6.283, d = 20 + r() * 50, x = Math.cos(a) * d, z = Math.sin(a) * d;
      if (W.pathDist(x, z) < 2.4 || Math.hypot(x - 4, z - 26) < 10 || HM.height(x, z) < WATER + 0.12 || W.WAY.some((w) => Math.hypot(x - w.x, z - w.z) < 3)) continue;
      (r() < 0.25 ? pine : deadTree)(x, z, 0.8 + r() * 0.6, r);
    }
    for (let i = 0; i < 90; i++) {
      const a = r() * 6.283, d = 9 + r() * 62, x = Math.cos(a) * d, z = Math.sin(a) * d;
      if (W.pathDist(x, z) < 1.6 || Math.hypot(x, z) < 8) continue;
      rock(x, z, 0.16 + r() * r() * 0.9, r, false);
    }
    // Ashenvale Academy: a dark shape on the northern rise
    const ag = new THREE.Group(); ag.position.set(16, 3, -150); ag.scale.setScalar(1.25);
    const am = mat(0x1a1c22, 0.95, { flatShading: true }); W.acadWin = glow(0xffa64a, 0);
    [[0, 0, 3.4, 34], [-11, 3, 2.4, 22], [12, 2, 2.7, 27], [-5.5, 5, 1.9, 18], [6, 5, 2.0, 21], [-19, 4, 1.6, 14], [20, 4, 1.7, 15]].forEach(([tx, tz, rad, h]) => {
      const t = new THREE.Mesh(new THREE.CylinderGeometry(rad * 0.9, rad, h, 9), am); t.position.set(tx, h / 2, tz); ag.add(t);
      const roof = new THREE.Mesh(new THREE.ConeGeometry(rad * 1.2, rad * 3.2, 9), am); roof.position.set(tx, h + rad * 1.6, tz); ag.add(roof);
      for (let k = 0; k < 4; k++) { const wn = new THREE.Mesh(new THREE.BoxGeometry(0.5, 1.0, 0.2), W.acadWin); const a = k * 1.2 - 0.9 + tx; wn.position.set(tx + Math.sin(a) * rad * 0.93, h * (0.45 + 0.13 * k), tz + Math.cos(a) * rad * 0.93); wn.rotation.y = a; ag.add(wn); }
    });
    const hall = new THREE.Mesh(new THREE.BoxGeometry(42, 10, 7), am); hall.position.set(0, 5, 4); ag.add(hall);
    scene.add(ag);
  }

  function buildHerbs(r) {
    const spots = [];
    for (let tries = 0; tries < 6000 && spots.length < 7; tries++) {
      const a = r() * 6.283, d = 18 + r() * 40, x = Math.cos(a) * d, z = Math.sin(a) * d, h = HM.height(x, z);
      if (h > WATER + 0.05 && h < WATER + 0.22 && W.pathDist(x, z) > 2 && spots.every((s) => Math.hypot(s.x - x, s.z - z) > 11)) spots.push({ x, z, h });
    }
    const pm = glow(0x7fc8ff, 5), sm = mat(0x1f3a22, 0.9);
    spots.forEach((s, i) => {
      const g = new THREE.Group(); g.position.set(s.x, s.h, s.z);
      for (let k = 0; k < 3; k++) {
        const a = k * 2.1 + i, st = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.016, 0.42, 4), sm); st.position.set(Math.cos(a) * 0.1, 0.21, Math.sin(a) * 0.1); st.rotation.z = Math.cos(a) * 0.25; st.rotation.x = Math.sin(a) * 0.25; g.add(st);
        const fl = new THREE.Mesh(new THREE.IcosahedronGeometry(0.06, 0), pm); fl.position.set(Math.cos(a) * 0.17, 0.44, Math.sin(a) * 0.17); fl.scale.y = 0.6; g.add(fl);
      }
      scene.add(g);
      const src = { pos: new THREE.Vector3(s.x, s.h + 0.5, s.z), col: new THREE.Color(0.35, 0.65, 1.0), i: 1.6, target: 1.6, lit: true, kind: 'herb', range: 5 };
      W.sources.push(src);
      W.herbs.push({ id: 'h' + i, x: s.x, z: s.z, group: g, src, taken: false });
    });
  }

  /* ---------- lights ---------- */
  function buildLights(q) {
    hemi = new THREE.HemisphereLight(0x2c4a7a, 0x0b0a08, 0.34); scene.add(hemi);
    moon = new THREE.DirectionalLight(0x8fb2f2, 1.9); moon.castShadow = true; moon.shadow.mapSize.set(q.shadow, q.shadow);
    const sc = moon.shadow.camera; sc.left = -26; sc.right = 26; sc.top = 26; sc.bottom = -26; sc.near = 1; sc.far = 130; moon.shadow.bias = -0.0015; moon.shadow.normalBias = 0.09; moon.shadow.radius = 3;
    scene.add(moon); scene.add(moon.target);
    fill = new THREE.DirectionalLight(0x8a9ab8, 0.14); fill.position.set(-0.5, 0.6, 0.6); scene.add(fill);
    for (let i = 0; i < q.pool; i++) { const p = new THREE.PointLight(0xffa24a, 0, 22, 1.5); scene.add(p); pool.push(p); }
  }

  W.init = (sc, q) => {
    scene = sc; initMats();
    const r = U.rng(20261112);
    buildSky(); buildLights(q);
    W.WAY.forEach(waylight);
    buildVillage(r); buildWilds(r); flushInstances();
    buildGround(); buildHerbs(r); buildGrass(q.grass);
  };

  /* push a circle out of everything solid; returns true if it touched something */
  W.resolve = (p, rad) => {
    let hit = false; const C = W.colliders;
    for (let it = 0; it < 2; it++) {
      for (const c of C.circles) { const dx = p.x - c.x, dz = p.z - c.z, d = Math.hypot(dx, dz), m = c.r + rad; if (d < m && d > 1e-5) { p.x = c.x + dx / d * m; p.z = c.z + dz / d * m; hit = true; } }
      for (const s of C.segs) {
        const abx = s.bx - s.ax, abz = s.bz - s.az, t = U.clamp(((p.x - s.ax) * abx + (p.z - s.az) * abz) / (abx * abx + abz * abz), 0, 1), qx = s.ax + abx * t, qz = s.az + abz * t;
        const dx = p.x - qx, dz = p.z - qz, d = Math.hypot(dx, dz), m = s.r + rad; if (d < m && d > 1e-5) { p.x = qx + dx / d * m; p.z = qz + dz / d * m; hit = true; }
      }
      for (const b of C.boxes) {
        const dx = p.x - b.x, dz = p.z - b.z; let lx = dx * b.c - dz * b.s, lz = dx * b.s + dz * b.c;
        const ox = b.hw + rad - Math.abs(lx), oz = b.hd + rad - Math.abs(lz);
        if (ox > 0 && oz > 0) { if (ox < oz) lx += Math.sign(lx || 1) * ox; else lz += Math.sign(lz || 1) * oz; p.x = b.x + lx * b.c + lz * b.s; p.z = b.z - lx * b.s + lz * b.c; hit = true; }
      }
    }
    return hit;
  };

  const tmpV = new THREE.Vector3(), cA = new THREE.Color(), cB = new THREE.Color();
  W.update = (dt, time, focus, playerPos, playerLight) => {
    const d = W.dawn, k = W.lit / W.WAY.length;
    // moon slides down and warms into a low sun as the dawn comes
    const md = tmpV.set(U.lerp(0.35, 0.9, d), U.lerp(0.3, 0.16, d), U.lerp(-0.89, 0.42, d)).normalize();
    skyU.uMoon.value.copy(d < 0.5 ? md : tmpV.set(0.35, 0.3, -0.89).normalize()); skyU.uDawn.value = d; skyU.uTime.value = time;
    tmpV.set(U.lerp(0.35, 0.9, d), U.lerp(0.3, 0.16, d), U.lerp(-0.89, 0.42, d)).normalize();
    moon.color.copy(cA.set(0x8fb2f2)).lerp(cB.set(0xffb070), d); moon.intensity = U.lerp(2.5 + k * 0.5, 5.2, d);
    hemi.color.copy(cA.set(0x2c4a7a)).lerp(cB.set(0x9fb6d8), d); hemi.groundColor.copy(cA.set(0x0b0a08)).lerp(cB.set(0x3a2f24), d); hemi.intensity = U.lerp(0.34 + k * 0.1, 1.5, d);
    const fx = Math.round(focus.x * 2) / 2, fz = Math.round(focus.z * 2) / 2;
    moon.target.position.set(fx, 0, fz); moon.position.set(fx + tmpV.x * 70, tmpV.y * 70, fz + tmpV.z * 70);
    // flames ease toward their targets and flicker
    for (const s of W.sources) { s.i = U.damp(s.i, s.target, 2.2, dt); s.fl = s.i * (1 + Math.sin(time * 9 + s.pos.x) * 0.045 + Math.sin(time * 23 + s.pos.z) * 0.025); }
    for (const w of W.waylights) w.glass.material.emissiveIntensity = w.src.i * 0.26;
    W.great.glass.material.emissiveIntensity = W.great.src.i * 0.16;
    const wi = (0.5 + k * 2.4) * (1 - d * 0.85); for (const m of W.windows) m.emissiveIntensity = wi;
    W.acadWin.emissiveIntensity = W.great.lit ? 3 : 1.1;
    W.fire.scale.y = 1 + Math.sin(time * 11) * 0.18; W.brew.material.emissiveIntensity = 1.0 + Math.sin(time * 2.1) * 0.3;
    // nearest burning flames get the real lights; the same list glows in the fog and on the grass
    const near = W.sources.filter((s) => s.i > 0.05).map((s) => ({ s, d: s.pos.distanceTo(focus) - (s.kind === 'great' ? 30 : 0) })).sort((a, b) => a.d - b.d);
    pool.forEach((p, i) => { const n = near[i]; if (n && n.d < 60) { p.position.copy(n.s.pos); p.color.copy(n.s.col); p.intensity = n.s.fl; p.distance = n.s.range; } else p.intensity = 0; });
    const L = HM.gfx.lights; L.length = 0;
    if (playerLight && playerLight.i > 0.01) L.push(playerLight);
    for (let i = 0; i < near.length && L.length < 6; i++) L.push({ pos: near[i].s.pos, col: near[i].s.col, i: near[i].s.fl * 0.045, raw: near[i].s.fl, range: near[i].s.range });
    const gu = grassU; gu.uCenter.value.copy(focus); gu.uPlayer.value.copy(playerPos); gu.uTime.value = time;
    gu.uMoonDir.value.copy(tmpV); gu.uMoonCol.value.set(moon.color.r * moon.intensity, moon.color.g * moon.intensity, moon.color.b * moon.intensity);
    gu.uHemiSky.value.set(hemi.color.r * hemi.intensity, hemi.color.g * hemi.intensity, hemi.color.b * hemi.intensity); gu.uHemiGnd.value.set(hemi.groundColor.r * hemi.intensity, hemi.groundColor.g * hemi.intensity, hemi.groundColor.b * hemi.intensity);
    for (let i = 0; i < NLG; i++) {
      const s = i === 0 && playerLight ? playerLight : (near[i - (playerLight ? 1 : 0)] || {}).s;
      if (i === 0 && playerLight) { gu.uLP.value[i].copy(playerLight.pos); gu.uLC.value[i].set(playerLight.col.r * playerLight.raw, playerLight.col.g * playerLight.raw, playerLight.col.b * playerLight.raw); gu.uLR.value[i] = playerLight.range; }
      else if (s) { gu.uLP.value[i].copy(s.pos); gu.uLC.value[i].set(s.col.r * s.fl, s.col.g * s.fl, s.col.b * s.fl); gu.uLR.value[i] = s.range; }
      else { gu.uLC.value[i].set(0, 0, 0); gu.uLR.value[i] = 1; }
    }
    waterU.uT.value = time;
    // every waylight pushes the dark back a little; the dawn clears it
    const P = HM.gfx.params;
    P.fogDens = U.lerp(U.lerp(0.019, 0.011, k), 0.0035, d);
    P.fogCol.setRGB(U.lerp(0.012, 0.42, d), U.lerp(0.02, 0.36, d), U.lerp(0.034, 0.38, d)); P.scatter = 1 - d * 0.85;
    P.warm = U.lerp(1.0, 0.55, d);
  };
})();
