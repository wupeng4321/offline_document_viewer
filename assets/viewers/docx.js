/* docx kabuğunun mantığı.
 *
 * docx-preview bu kopyada üç yama taşıyor (themeFill, themeTint/Shade,
 * `w:val="auto"` tema rengini ezme) — ayrıntı vendor/PATCHES-docx-preview.md.
 */
(function () {
  'use strict';

  const stage = document.getElementById('stage');
  let resizeProbes = 0;

  function probe(phase) {
    const wrapper = stage.querySelector('.docx-wrapper');
    const page = stage.querySelector('.docx-wrapper > section');
    const stageRect = stage.getBoundingClientRect();
    const wrapperRect = wrapper && wrapper.getBoundingClientRect();
    Bridge.send('layoutProbe', {
      phase: phase,
      ms: Math.round(performance.now()),
      viewportWidth: window.innerWidth,
      clientWidth: document.documentElement.clientWidth,
      stageWidth: Math.round(stageRect.width),
      stageHeight: Math.round(stageRect.height),
      wrapperWidth: wrapper ? wrapper.offsetWidth : null,
      wrapperHeight: wrapper ? wrapper.offsetHeight : null,
      visualWidth: wrapperRect ? Math.round(wrapperRect.width) : null,
      pageWidth: page ? page.offsetWidth : null,
      transform: wrapper ? wrapper.style.transform : null,
      styleWidth: wrapper ? wrapper.style.width : null,
      visibility: stage.style.visibility
    });
  }

  /* Word sayfası sabit genişlikte (A4 ≈ 794 px); telefon ekranı ~390 px.
     Ölçekleyerek sığdırıyoruz — yatay kaydırma bir belge okuyucuda kabul
     edilemez. Ölçek düzeni bozmuyor, yalnızca küçültüyor; kullanıcı
     yakınlaştırma jestiyle büyütebiliyor. */
  function fitToWidth() {
    const wrapper = stage.querySelector('.docx-wrapper');
    if (!wrapper) {
      return;
    }
    wrapper.style.transform = '';
    wrapper.style.height = '';
    wrapper.style.width = '';
    const page = stage.querySelector('.docx-wrapper > section');
    if (!page) {
      return;
    }
    const pageWidth = page.offsetWidth;
    if (!pageWidth) {
      return;
    }
    const available = document.documentElement.clientWidth;
    const scale = Math.min(1, available / pageWidth);
    if (scale >= 1) {
      return;
    }
    wrapper.style.transformOrigin = 'top left';
    wrapper.style.transform = 'scale(' + scale + ')';
    // Ölçeklenen eleman düzen yüksekliğini korur; kapsayıcıyı da küçültüyoruz
    // ki altta boşluk kalmasın.
    wrapper.style.height = wrapper.offsetHeight * scale + 'px';
    wrapper.style.width = available + 'px';
  }

  /** Anahat için başlıkları toplar — görüntüleyicideki "İçindekiler". */
  function collectOutline() {
    const headings = stage.querySelectorAll('h1, h2, h3');
    const labels = [];
    headings.forEach(function (node, index) {
      const text = (node.textContent || '').trim();
      if (text) {
        node.setAttribute('data-outline', String(index));
        labels.push(text);
      }
    });
    return labels;
  }

  async function render(bytes) {
    const started = performance.now();
    stage.style.visibility = 'hidden';
    stage.innerHTML = '';
    probe('render-start');

    await docx.renderAsync(bytes, stage, null, {
      className: 'docx',
      inWrapper: true,
      breakPages: true,
      experimental: true,
      // Görselleri data URI olarak göm: blob URL'leri sıkı CSP altında
      // engellenebiliyor, data: img-src'de açıkça izinli.
      useBase64URL: true,
      renderHeaders: true,
      renderFooters: true,
      renderFootnotes: true
    });

    probe('render-complete');
    fitToWidth();
    probe('fitted');
    const outline = collectOutline();
    stage.style.visibility = 'visible';
    probe('visible');
    requestAnimationFrame(function () {
      probe('paint-frame-1');
      requestAnimationFrame(function () {
        probe('paint-frame-2');
      });
    });

    Bridge.send('rendered', {
      ms: Math.round(performance.now() - started),
      units: stage.querySelectorAll('.docx-wrapper > section').length || 1,
      styled: true,
      outline: outline
    });
  }

  Bridge.on('goto', function (payload) {
    const target = stage.querySelector('[data-outline="' + payload.index + '"]');
    if (target) {
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  });

  Bridge.on('search', function (payload) {
    const query = (payload.query || '').toLocaleLowerCase('tr');

    // Önceki vurguları temizle.
    stage.querySelectorAll('mark.hit').forEach(function (mark) {
      const parent = mark.parentNode;
      parent.replaceChild(document.createTextNode(mark.textContent), mark);
      parent.normalize();
    });

    if (!query) {
      Bridge.send('searchResult', { hits: 0 });
      return;
    }

    let hits = 0;
    const walker = document.createTreeWalker(stage, NodeFilter.SHOW_TEXT);
    const targets = [];
    while (walker.nextNode()) {
      const node = walker.currentNode;
      if (node.nodeValue.toLocaleLowerCase('tr').indexOf(query) >= 0) {
        targets.push(node);
      }
    }

    targets.forEach(function (node) {
      const value = node.nodeValue;
      const lower = value.toLocaleLowerCase('tr');
      const fragment = document.createDocumentFragment();
      let cursor = 0;
      let found = lower.indexOf(query, cursor);
      while (found >= 0) {
        fragment.appendChild(
          document.createTextNode(value.slice(cursor, found))
        );
        const mark = document.createElement('mark');
        mark.className = 'hit';
        mark.textContent = value.slice(found, found + query.length);
        fragment.appendChild(mark);
        hits++;
        cursor = found + query.length;
        found = lower.indexOf(query, cursor);
      }
      fragment.appendChild(document.createTextNode(value.slice(cursor)));
      node.parentNode.replaceChild(fragment, node);
    });

    const first = stage.querySelector('mark.hit');
    if (first) {
      first.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
    Bridge.send('searchResult', { hits: hits });
  });

  window.addEventListener('resize', function () {
    const logResize = resizeProbes++ < 3;
    if (logResize) probe('resize-before');
    fitToWidth();
    if (logResize) probe('resize-after');
  });

  Bridge.start(render);
})();
