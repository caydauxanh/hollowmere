const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'] });
  const pg = await b.newPage({ viewport: { width: 960, height: 540 } });
  const errs = []; pg.on('console', m => { if (m.type()==='error') errs.push(m.text().slice(0,300)); }); pg.on('pageerror', e => errs.push('PAGEERR '+e.message));
  await pg.goto('file://' + __dirname + '/dist/index.html?q=low');
  await pg.waitForTimeout(5000);
  const ev = (s) => pg.evaluate(s); const shot = (n) => pg.screenshot({ path: __dirname + '/../shots/f_' + n + '.png', timeout: 120000 });
  const frames = async (n) => { const f0 = await ev('__g.frames()'); for (let i = 0; i < 400; i++) { await pg.waitForTimeout(250); if (await ev('__g.frames()') - f0 >= n) return; } };
  const ok = (name, c) => console.log((c ? 'PASS ' : 'FAIL ') + name);
  await pg.click('#begin'); await frames(5);
  ok('title hidden', await ev('!document.getElementById("title").classList.contains("on")'));
  // walk forward with W: position must change
  const p0 = await ev('__g.info().pos'); await pg.keyboard.down('KeyW'); await frames(25); await pg.keyboard.up('KeyW'); const p1 = await ev('__g.info().pos');
  ok('walks ' + JSON.stringify(p1), Math.hypot(p1[0]-p0[0], p1[1]-p0[1]) > 0.5);
  // waylight before Wren: refused
  await ev('__g.tp(5.2,12.2)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(6);
  ok('gate refused before Wren', (await ev('__g.info().lit')) === 0);
  await ev('__g.tp(4.3,17.2)'); await frames(4);
  ok('prompt Wren: ' + await ev('document.getElementById("ptext").textContent'), await ev('document.getElementById("prompt").classList.contains("on")'));
  await pg.keyboard.press('KeyE'); await frames(8); await shot('talk');
  ok('talking', await ev('__g.HM.ui.talking'));
  for (let i = 0; i < 12 && await ev('__g.HM.ui.talking'); i++) { await pg.keyboard.press('KeyE'); await frames(3); }
  ok('wren met', await ev('__g.info().state.wren'));
  await ev('__g.tp(5.2,12.2)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(36); await shot('kindle');
  ok('gate lit', (await ev('__g.info().lit')) === 1);
  // wood needs bramble
  await ev('__g.tp(-25.5,-29)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(8);
  ok('wood refused', (await ev('__g.info().lit')) === 1);
  await ev('__g.tp(-14.4,-14.2)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(4);
  for (let i = 0; i < 12 && await ev('__g.HM.ui.talking'); i++) { await pg.keyboard.press('KeyE'); await frames(3); }
  ok('bramble word', await ev('__g.info().state.bramble'));
  await ev('__g.tp(-25.5,-29)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(36);
  ok('wood lit', (await ev('__g.info().lit')) === 2);
  // every waylight reachable prompt, kindle the rest for real
  const ways = await ev('__g.HM.world.waylights.map(w=>[w.x,w.z,w.lit])');
  for (const w of ways) if (!w[2]) { const k = 1.6 / Math.hypot(w[0], w[1]); await ev(`__g.tp(${w[0]*(1-k)},${w[1]*(1-k)})`); await frames(4); await pg.keyboard.press('KeyE'); await frames(36); }
  ok('all seven lit', (await ev('__g.info().lit')) === 7);
  // great lantern refused without oil
  await ev('__g.tp(0.5,3.2)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(8);
  ok('great refused without oil', !(await ev('__g.info().state.great')));
  // herbs
  const herbs = await ev('__g.HM.world.herbs.map(h=>[h.x,h.z])'); console.log('herbs', JSON.stringify(herbs.map(h=>h.map(Math.round))));
  for (let i = 0; i < 3; i++) { await ev(`__g.tp(${herbs[i][0]+0.5},${herbs[i][1]+0.4})`); await frames(4); if (i===0) await shot('herb'); await pg.keyboard.press('KeyE'); await frames(5); }
  ok('3 petals', (await ev('__g.info().state.petals')) === 3);
  await ev('__g.tp(-2.3,-9.9)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(4);
  for (let i = 0; i < 12 && await ev('__g.HM.ui.talking'); i++) { await pg.keyboard.press('KeyE'); await frames(3); }
  ok('oil', await ev('__g.info().state.oil'));
  await ev('__g.tp(0.5,3.2);__g.cam(0.4,0.2,1.2)'); await frames(4); await pg.keyboard.press('KeyE'); await frames(52); await shot('great');
  ok('great lit', await ev('__g.info().state.great'));
  await ev('__g.HM.world.dawn=0.97'); await frames(40); await shot('dawn');
  // reload: save persists
  await pg.reload(); await pg.waitForTimeout(5000);
  ok('continue offered', (await ev('document.getElementById("begin").textContent')) === 'Continue');
  console.log('errors', errs.length, errs.slice(0,6).join('\n'));
  await b.close();
})();
