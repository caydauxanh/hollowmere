const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist','--autoplay-policy=no-user-gesture-required']});
  const pg = await b.newPage({viewport:{width:800,height:450}});
  const errs=[];
  pg.on('console', m => { const t=m.text(); if (/error/i.test(t)) errs.push(t.slice(0,300)); });
  pg.on('pageerror', e => errs.push('pageerror: '+e.message));
  await pg.goto('http://localhost:8765/hollowmere.html');
  await pg.waitForFunction(() => document.getElementById('load').hidden, {timeout: 300000});
  await pg.waitForFunction(() => window.__dbg, {timeout: 120000});
  const dbg = async () => pg.evaluate(() => window.__dbg);
  const cmd = async (c) => { await pg.evaluate((c) => { window.__cmd = c; }, c); await pg.waitForTimeout(600); };
  // close title/intro
  for (let i = 0; i < 6; i++) { await pg.keyboard.press('KeyF'); await pg.waitForTimeout(700); }
  await cmd('begin'); await pg.waitForTimeout(1500); for (let i = 0; i < 4; i++) { await pg.keyboard.press('KeyF'); await pg.waitForTimeout(700); } await cmd('close'); await cmd('hour 12'); await pg.waitForTimeout(800);
  console.log('start', JSON.stringify(await dbg()));
  const fps = await pg.evaluate(() => new Promise(r => { let n=0; const t0=performance.now(); function f(){ n++; if (performance.now()-t0 < 3000) requestAnimationFrame(f); else r(n/3); } requestAnimationFrame(f); }));
  console.log('fps', fps);
  async function walk(key, ms) { await pg.keyboard.down(key); await pg.waitForTimeout(ms); await pg.keyboard.up(key); await pg.waitForTimeout(400); }
  // Test 1: house at (13,-10): teleport to (13,-5.5) -> walk north (W moves -z? camera-relative; use default yaw)
  const tests = [
    ['house (13,-10) from south', 'tp 13 0.2 -5.5', 'KeyW', 12000, (a,b)=> b.z > -8.6],
    ['church (18,-30) from east', 'tp 24 0.2 -30', 'KeyA', 12000, (a,b)=> b.x > 20.5],
    ['bridge deck reachable', 'tp -32 0.2 24.5', 'KeyA', 15000, (a,b)=> b.y > 0.5 || b.x < -41],
    ['tree Tree_oak at (-20,-2) from east', 'tp -16.5 0.2 -2', 'KeyA', 12000, (a,b)=> b.x > -19.4],
    ['river at z=46 from north', 'tp -4 0.2 40', 'KeyS', 15000, (a,b)=> b.z < 44.2],
    ['lake west shore x=38', 'tp 33 0.2 14', 'KeyD', 15000, (a,b)=> b.x < 38.5],
    ['open meadow (should move)', 'tp -30 0.2 -60', 'KeyW', 12000, (a,b)=> Math.abs(b.z-a.z) > 3],
  ];
  for (const [name, tp, key, ms, ok] of tests) {
    await cmd('close'); await cmd(tp); await pg.waitForTimeout(3000); const a = await dbg(); await walk(key, ms); await pg.waitForTimeout(3000); const bb = await dbg();
    console.log((ok(a,bb) ? 'OK   ' : 'FAIL ') + name + ' dlg=' + a.dlg + '/' + bb.dlg + '  ' + JSON.stringify([a.x,a.z]) + ' -> ' + JSON.stringify([bb.x,bb.y,bb.z]));
  }
  await pg.screenshot({path:'shots/webphys.png'});
  console.log('errors:', errs.length); errs.slice(0,8).forEach(e=>console.log(' ', e));
  await b.close();
})().catch(e=>{console.log('ERR',e.message);process.exit(1)});
