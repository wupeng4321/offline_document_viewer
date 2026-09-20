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
      innerWidth: 1,
      addEventListener: (name, handler) => events.set(name, handler),
      jQuery: () => ({ pptxToHtml() {} }),
    },
    Bridge: { on() {}, send: (type, payload) => extras.sent?.(type, payload), start: (callback) => { render = callback; } },
    performance: { now: () => 100 },
    requestAnimationFrame: (callback) => { (extras.frames ||= []).push(callback); },
    MutationObserver: class { constructor(callback) { extras.notify = callback; } observe() {} },
    setTimeout: (callback) => { callback(); return 1; },
    clearTimeout() {},
    DataTransfer: class { constructor() { this.items = { add() {} }; this.files = []; } },
    File: class {},
    Event: class {},
    docx: extras.docx || { async renderAsync() {} },
  };
  const source = fs.readFileSync(
    path.join(__dirname, '..', 'assets', 'viewers', `${name}.js`), 'utf8',
  );
  vm.runInNewContext(source, context, { filename: `${name}.js` });
  return {
    render,
    flushFrame() {
      assert.ok(extras.frames?.length, `${name} must have a pending frame`);
      extras.frames.shift()();
    },
    resize(width) {
      document.documentElement.clientWidth = width;
      context.window.innerWidth = width;
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
  const stage = { style: {}, querySelectorAll: () => [slide] };
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

test('PPTX stays hidden until the scaled layout has painted', async () => {
  const slide = {
    offsetWidth: 960,
    offsetHeight: 540,
    style: {},
    textContent: 'Title',
    setAttribute() {},
  };
  const stage = { style: {}, querySelectorAll: () => [slide] };
  const messages = [];
  const extras = {
    sent: (type) => { if (type === 'rendered') messages.push(type); },
  };
  const viewer = loadViewer('pptx', stage, extras);

  await viewer.render(new Uint8Array());
  assert.equal(stage.style.visibility, 'hidden');
  extras.notify();
  assert.equal(stage.style.visibility, 'hidden');
  assert.deepEqual(messages, []);

  viewer.flushFrame();
  assert.equal(stage.style.visibility, 'hidden');
  assert.deepEqual(messages, []);

  viewer.flushFrame();
  assert.equal(stage.style.visibility, 'visible');
  assert.deepEqual(messages, ['rendered']);
});

test('DOCX page refits without accumulating the previous scaled height', async () => {
  const page = {
    offsetWidth: 800,
    getBoundingClientRect() { return { width: 300 }; },
  };
  const wrapper = {
    style: {},
    getBoundingClientRect() { return { width: this.offsetWidth }; },
    offsetWidth: 800,
    get offsetHeight() { return parseFloat(this.style.height) || 1000; },
  };
  const stage = {
    style: {},
    getBoundingClientRect() { return { width: 300, height: 400 }; },
    querySelector: (selector) => selector === '.docx-wrapper' ? wrapper : page,
    querySelectorAll: (selector) => selector === '.docx-wrapper > section' ? [page] : [],
  };
  const viewer = loadViewer('docx', stage);
  const rendering = viewer.render(new Uint8Array());
  await new Promise(setImmediate);
  viewer.flushFrame();
  viewer.flushFrame();
  await rendering;
  assert.equal(wrapper.style.transform, 'scale(0.00125)');

  viewer.resize(300);
  assert.equal(wrapper.style.transform, 'scale(0.375)');
  assert.equal(wrapper.style.height, '375px');
});

test('DOCX hides partial content until layout and rendering finish', async () => {
  let finishRender;
  const pendingContent = new Promise((resolve) => { finishRender = resolve; });
  const page = {
    offsetWidth: 800,
    getBoundingClientRect() { return { width: 300 }; },
  };
  const wrapper = {
    style: {}, offsetWidth: 800, offsetHeight: 1000,
    getBoundingClientRect() { return { width: this.offsetWidth }; },
  };
  const stage = {
    style: {},
    innerHTML: '',
    getBoundingClientRect() { return { width: 300, height: 400 }; },
    querySelector: (selector) => selector === '.docx-wrapper' ? wrapper : page,
    querySelectorAll: (selector) => selector === '.docx-wrapper > section' ? [page] : [],
  };
  const messages = [];
  const probes = [];
  const extras = {
    sent: (type, payload) => {
      if (type === 'rendered') messages.push(type);
      if (type === 'layoutProbe') probes.push(payload);
    },
    docx: { async renderAsync() {
      stage.innerHTML = '<section>partial document</section>';
      await pendingContent;
    } },
  };
  const viewer = loadViewer('docx', stage, extras);

  const rendering = viewer.render(new Uint8Array());
  assert.equal(stage.style.visibility, 'hidden');
  assert.equal(stage.innerHTML, '<section>partial document</section>');
  assert.deepEqual(messages, []);

  finishRender();
  await new Promise(setImmediate);
  assert.equal(stage.style.visibility, 'hidden');
  assert.deepEqual(messages, []);
  assert.deepEqual(probes.map((probe) => probe.phase), [
    'render-start', 'render-complete', 'fitted',
  ]);

  viewer.flushFrame();
  assert.equal(stage.style.visibility, 'hidden');
  assert.deepEqual(messages, []);

  viewer.flushFrame();
  await rendering;
  assert.equal(stage.style.visibility, 'visible');
  assert.deepEqual(messages, ['rendered']);
  assert.deepEqual(probes.slice(-3).map((probe) => probe.phase), [
    'paint-frame-1', 'paint-frame-2', 'visible',
  ]);

  viewer.resize(300);
  assert.deepEqual(probes.slice(-5).map((probe) => probe.phase), [
    'paint-frame-1', 'paint-frame-2', 'visible', 'resize-before', 'resize-after',
  ]);
  assert.equal(probes.at(-1).clientWidth, 300);
  assert.equal(probes.at(-1).pageVisualWidth, 300);
});
