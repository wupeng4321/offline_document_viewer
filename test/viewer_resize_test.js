const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

function loadViewer(name, stage, extras = {}) {
  const events = new Map();
  let render;
  const document = {
    documentElement: { clientWidth: 1 },
    getElementById: () => stage,
    createElement: () => ({ style: {}, dispatchEvent() {} }),
    body: { appendChild() {} },
  };
  const context = {
    document,
    window: {
      addEventListener: (name, handler) => events.set(name, handler),
      jQuery: () => ({ pptxToHtml() {} }),
    },
    Bridge: { on() {}, send() {}, start: (callback) => { render = callback; } },
    performance: { now: () => 100 },
    MutationObserver: class { constructor(callback) { extras.notify = callback; } observe() {} },
    setTimeout: (callback) => { callback(); return 1; },
    clearTimeout() {},
    DataTransfer: class { constructor() { this.items = { add() {} }; this.files = []; } },
    File: class {},
    Event: class {},
    docx: { async renderAsync() {} },
  };
  const source = fs.readFileSync(
    path.join(__dirname, '..', 'assets', 'viewers', `${name}.js`), 'utf8',
  );
  vm.runInNewContext(source, context, { filename: `${name}.js` });
  return {
    render,
    resize(width) {
      document.documentElement.clientWidth = width;
      assert.ok(events.has('resize'), `${name} must respond to viewport resize`);
      events.get('resize')();
    },
  };
}

test('PPTX slide refits after the WebView grows from 1 to 300 pixels', async () => {
  const slide = {
    offsetWidth: 960,
    offsetHeight: 540,
    style: {},
    textContent: 'Title',
    setAttribute() {},
  };
  const stage = { querySelectorAll: () => [slide] };
  const extras = {};
  const viewer = loadViewer('pptx', stage, extras);
  await viewer.render(new Uint8Array());
  extras.notify();
  assert.equal(slide.style.transform, 'scale(0.0010416666666666667)');

  viewer.resize(300);
  assert.equal(slide.style.transform, 'scale(0.3125)');

  viewer.resize(1200);
  assert.equal(slide.style.transform, '');
  assert.equal(slide.style.marginRight, '');
});

test('DOCX page refits without accumulating the previous scaled height', async () => {
  const page = { offsetWidth: 800 };
  const wrapper = {
    style: {},
    get offsetHeight() { return parseFloat(this.style.height) || 1000; },
  };
  const stage = {
    querySelector: (selector) => selector === '.docx-wrapper' ? wrapper : page,
    querySelectorAll: (selector) => selector === '.docx-wrapper > section' ? [page] : [],
  };
  const viewer = loadViewer('docx', stage);
  await viewer.render(new Uint8Array());
  assert.equal(wrapper.style.transform, 'scale(0.00125)');

  viewer.resize(300);
  assert.equal(wrapper.style.transform, 'scale(0.375)');
  assert.equal(wrapper.style.height, '375px');
});
