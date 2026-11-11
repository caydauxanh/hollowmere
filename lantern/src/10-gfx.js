/* HOLLOWMERE — render pipeline: HDR scene -> height fog + light in-scatter -> bloom -> depth blur, tonemap, grade, grain */
(function () {
  const G = HM.gfx = {};
  const NL = 6;   // lights that glow in the fog
  let renderer, rtScene, rtA, rtB = [], qscene, qcam, quad, mFog, mDown, mFinal, W = 2, H = 2;
  G.params = { exposure: 1.0, bloom: 0.55, vignette: 1.0, fogDens: 0.02, fogCol: new THREE.Color(0.012, 0.02, 0.034), scatter: 1.0, focus: 9, dof: 1.0, warm: 1.0, flash: 0, sat: 1.0, fade: 0 };
  G.lights = [];   // {pos:Vector3, col:Color, i:number} set every frame by the world

  const FS_V = 'varying vec2 vUv; void main(){ vUv = uv; gl_Position = vec4(position.xy, 0., 1.); }';

  G.init = (canvas) => {
    renderer = G.renderer = new THREE.WebGLRenderer({ canvas, antialias: false, powerPreference: 'high-performance', alpha: false, stencil: false });
    renderer.outputColorSpace = THREE.LinearSRGBColorSpace;
    renderer.toneMapping = THREE.NoToneMapping;
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    renderer.info.autoReset = true;
    const gl = renderer.getContext();
    G.hdr = !!(gl.getExtension('EXT_color_buffer_half_float') || gl.getExtension('EXT_color_buffer_float'));
    qscene = new THREE.Scene(); qcam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
    quad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), null); quad.frustumCulled = false; qscene.add(quad);

    mFog = new THREE.ShaderMaterial({
      depthTest: false, depthWrite: false, vertexShader: FS_V,
      uniforms: { tC: { value: null }, tD: { value: null }, uInvProj: { value: new THREE.Matrix4() }, uCamW: { value: new THREE.Matrix4() }, uFog: { value: new THREE.Color() }, uDens: { value: 0.02 }, uScat: { value: 1 },
        uLP: { value: Array.from({ length: NL }, () => new THREE.Vector3()) }, uLC: { value: Array.from({ length: NL }, () => new THREE.Vector3()) }, uSkyMix: { value: 0.3 } },
      fragmentShader: `precision highp float; precision highp sampler2D; varying vec2 vUv;
uniform sampler2D tC, tD; uniform mat4 uInvProj, uCamW; uniform vec3 uFog; uniform float uDens, uScat, uSkyMix;
uniform vec3 uLP[${NL}]; uniform vec3 uLC[${NL}];
void main(){
  vec3 col = texture2D(tC, vUv).rgb;
  float d = texture2D(tD, vUv).x;
  vec4 v = uInvProj * vec4(vUv*2.-1., d*2.-1., 1.); v /= v.w;
  vec3 wp = (uCamW * vec4(v.xyz, 1.)).xyz;
  vec3 ro = uCamW[3].xyz; vec3 rd = wp - ro; float t = length(rd); rd /= max(t, 1e-4);
  bool sky = d > 0.99999;
  float tt = sky ? 90. : min(t, 140.);
  // height fog: thick in the hollows, thin above head height
  float hmid = ro.y + rd.y * tt * .5;
  float hf = exp(-max(hmid + .4, 0.) * .16);
  float fa = 1. - exp(-tt * uDens * (.35 + 1.1*hf));
  // light in-scatter: exact integral of 1/(a+s^2) along the ray for each lantern
  vec3 sc = vec3(0.);
  for (int i = 0; i < ${NL}; i++){
    vec3 L = uLP[i] - ro; float s0 = dot(L, rd); float a = max(dot(L, L) - s0*s0, 0.) + .35;
    float sa = sqrt(a);
    float integ = (atan((tt - s0)/sa) - atan(-s0/sa)) / sa;
    sc += uLC[i] * integ;
  }
  vec3 fogc = uFog + sc * uDens * 2.4 * uScat;
  if (sky) { col = mix(col, fogc, fa * uSkyMix) + sc * uDens * .8 * uScat; }
  else { col = mix(col, fogc, fa) ; }
  gl_FragColor = vec4(col, 1.);
}` });

    mDown = new THREE.ShaderMaterial({
      depthTest: false, depthWrite: false, vertexShader: FS_V, uniforms: { tC: { value: null }, uTx: { value: new THREE.Vector2() }, uThr: { value: 0 } },
      fragmentShader: `precision highp float; precision highp sampler2D; varying vec2 vUv; uniform sampler2D tC; uniform vec2 uTx; uniform float uThr;
void main(){
  vec3 c = texture2D(tC, vUv).rgb * 4.;
  c += texture2D(tC, vUv + uTx*vec2( 1., 1.)).rgb; c += texture2D(tC, vUv + uTx*vec2(-1., 1.)).rgb;
  c += texture2D(tC, vUv + uTx*vec2( 1.,-1.)).rgb; c += texture2D(tC, vUv + uTx*vec2(-1.,-1.)).rgb;
  c /= 8.;
  if (uThr > 0.) { float l = max(c.r, max(c.g, c.b)); c *= smoothstep(uThr*.6, uThr*1.6, l); }
  gl_FragColor = vec4(min(c, vec3(40.)), 1.);
}` });

    mFinal = new THREE.ShaderMaterial({
      depthTest: false, depthWrite: false, vertexShader: FS_V,
      uniforms: { tC: { value: null }, tD: { value: null }, tB1: { value: null }, tB2: { value: null }, tB3: { value: null }, tB4: { value: null }, uRes: { value: new THREE.Vector2() }, uTime: { value: 0 },
        uExp: { value: 1 }, uBloom: { value: 0.5 }, uVig: { value: 1 }, uFlash: { value: 0 }, uSat: { value: 1 }, uWarm: { value: 1 }, uNF: { value: new THREE.Vector2(0.3, 400) }, uFocus: { value: 9 }, uDof: { value: 1 }, uFade: { value: 0 } },
      fragmentShader: `precision highp float; precision highp sampler2D; varying vec2 vUv;
uniform sampler2D tC, tD, tB1, tB2, tB3, tB4; uniform vec2 uRes, uNF; uniform float uTime, uExp, uBloom, uVig, uFlash, uSat, uWarm, uFocus, uDof, uFade;
vec3 aces(vec3 x){ return clamp((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14), 0., 1.); }
float hash(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); }
void main(){
  vec3 sharp = texture2D(tC, vUv).rgb;
  vec3 b1 = texture2D(tB1, vUv).rgb, b2 = texture2D(tB2, vUv).rgb, b3 = texture2D(tB3, vUv).rgb, b4 = texture2D(tB4, vUv).rgb;
  // depth blur: far background and things right at the lens go soft
  float d = texture2D(tD, vUv).x; float z = uNF.x*uNF.y / (uNF.y - d*(uNF.y - uNF.x));
  float coc = clamp(max((z - uFocus*1.9) / (uFocus*4.), (uFocus*.33 - z) / (uFocus*.3)), 0., 1.) * uDof;
  vec3 col = mix(sharp, mix(b1, b2, coc), coc*.85);
  vec3 bloom = b1*.30 + b2*.30 + b3*.24 + b4*.16;
  col += bloom * uBloom;
  col += uFlash * vec3(1., .8, .55);
  col *= uExp;
  // split tone before the curve: cool the shadows, warm the lights
  float l = dot(col, vec3(.2126,.7152,.0722));
  col *= mix(vec3(.80,.95,1.22), vec3(1.14,1.0,.82), smoothstep(.02, .55, l) * uWarm + (1.-uWarm)*.5);
  col = aces(col);
  float l2 = dot(col, vec3(.2126,.7152,.0722));
  col = mix(vec3(l2), col, uSat);
  vec2 q = (vUv - .5) * vec2(1.1, 1.); float v = smoothstep(.34, .98, length(q));
  col *= 1. - v*.62*uVig;
  col = pow(col, vec3(1./2.2));
  col += (hash(vUv*uRes + fract(uTime)*71.) - .5) * .03;
  col = mix(col, vec3(.012,.013,.02), uFade);
  gl_FragColor = vec4(col, 1.);
}` });
  };

  G.resize = (cssW, cssH, scale) => {
    W = Math.max(2, Math.floor(cssW * scale)); H = Math.max(2, Math.floor(cssH * scale));
    renderer.setPixelRatio(1); renderer.setSize(W, H, false);
    const type = G.hdr ? THREE.HalfFloatType : THREE.UnsignedByteType;
    const mk = (w, h, depth) => {
      const rt = new THREE.WebGLRenderTarget(w, h, { type, minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, depthBuffer: !!depth, stencilBuffer: false });
      if (depth) { rt.depthTexture = new THREE.DepthTexture(w, h); rt.depthTexture.type = THREE.UnsignedIntType; rt.depthTexture.minFilter = rt.depthTexture.magFilter = THREE.NearestFilter; }
      return rt;
    };
    [rtScene, rtA, ...rtB].forEach((r) => r && r.dispose());
    rtScene = mk(W, H, true); rtA = mk(W, H, false); rtB = [];
    let w = W, h = H;
    for (let i = 0; i < 4; i++) { w = Math.max(2, w >> 1); h = Math.max(2, h >> 1); rtB.push(mk(w, h, false)); }
    G.W = W; G.H = H;
  };

  const pass = (mat, target) => { quad.material = mat; renderer.setRenderTarget(target); renderer.render(qscene, qcam); };

  G.render = (scene, camera, time) => {
    const p = G.params;
    renderer.setRenderTarget(rtScene); renderer.render(scene, camera);
    // fog + in-scatter
    let u = mFog.uniforms; u.tC.value = rtScene.texture; u.tD.value = rtScene.depthTexture;
    u.uInvProj.value.copy(camera.projectionMatrixInverse); u.uCamW.value.copy(camera.matrixWorld);
    u.uFog.value.copy(p.fogCol); u.uDens.value = p.fogDens; u.uScat.value = p.scatter;
    for (let i = 0; i < NL; i++) {
      const L = G.lights[i];
      if (L) { u.uLP.value[i].copy(L.pos); u.uLC.value[i].set(L.col.r * L.i, L.col.g * L.i, L.col.b * L.i); } else { u.uLC.value[i].set(0, 0, 0); }
    }
    pass(mFog, rtA);
    // bloom chain
    let src = rtA;
    for (let i = 0; i < 4; i++) { mDown.uniforms.tC.value = src.texture; mDown.uniforms.uTx.value.set(1 / src.width, 1 / src.height); mDown.uniforms.uThr.value = i === 0 ? (G.hdr ? 1.0 : 0.72) : 0; pass(mDown, rtB[i]); src = rtB[i]; }
    u = mFinal.uniforms; u.tC.value = rtA.texture; u.tD.value = rtScene.depthTexture; u.tB1.value = rtB[0].texture; u.tB2.value = rtB[1].texture; u.tB3.value = rtB[2].texture; u.tB4.value = rtB[3].texture;
    u.uRes.value.set(W, H); u.uTime.value = time; u.uExp.value = p.exposure; u.uBloom.value = p.bloom; u.uVig.value = p.vignette; u.uFlash.value = p.flash; u.uSat.value = p.sat; u.uWarm.value = p.warm;
    u.uNF.value.set(camera.near, camera.far); u.uFocus.value = p.focus; u.uDof.value = p.dof; u.uFade.value = p.fade;
    pass(mFinal, null);
  };
})();
