const { chromium, devices } = require('playwright');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'] });
  const ctx = await b.newContext({ ...devices['iPhone 13'] }); const pg = await ctx.newPage();
  const errs = []; pg.on('console', m => { if (m.type()==='error') errs.push(m.text().slice(0,300)); }); pg.on('pageerror', e => errs.push('PAGEERR '+e.message));
  await pg.goto('file://' + __dirname + '/dist/index.html?q=low&fix=1'); await pg.waitForTimeout(5000);
  await pg.tap('#begin'); await pg.waitForTimeout(3000);
  const p0 = await pg.evaluate('__g.info().pos');
  const cdp = await ctx.newCDPSession(pg);
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 80, y: 600, id: 1 }] });
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 80, y: 540, id: 1 }] });
  await pg.waitForTimeout(6000);
  await pg.screenshot({ path: __dirname + '/../shots/m2.png', timeout: 120000 });
  await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
  const p1 = await pg.evaluate('__g.info().pos');
  console.log('stick walk', p0, p1, Math.hypot(p1[0]-p0[0], p1[1]-p0[1]) > 0.4 ? 'PASS' : 'FAIL', 'coarse tier', await pg.evaluate('__g.q.grass'));
  console.log('errors', errs.length, errs.join('\n'));
  await b.close();
})();
