const { chromium } = require('playwright');
(async () => {
  const args = process.argv.slice(2); const out = args[0]; const W = +(args[1]||1280), H = +(args[2]||720); const query = args[3]||'q=high&skip=new'; const js = args[4]||''; const wait = +(args[5]||6000);
  const b = await chromium.launch({ args: ['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'] });
  const pg = await b.newPage({ viewport: { width: W, height: H } });
  const errs = []; pg.on('console', m => { if (m.type()==='error'||m.type()==='warning') errs.push(m.text().slice(0,300)); }); pg.on('pageerror', e => errs.push('PAGEERR '+e.message));
  await pg.goto('file://' + __dirname + '/dist/index.html?' + query);
  await pg.waitForTimeout(wait);
  if (js) { console.log('js:', JSON.stringify(await pg.evaluate(js))); await pg.waitForTimeout(wait); }
  console.log('info', JSON.stringify(await pg.evaluate('window.__g&&__g.info()')));
  await pg.screenshot({ path: out, timeout: 120000 });
  console.log('errors', errs.length, errs.slice(0,8).join('\n'));
  await b.close();
})();
