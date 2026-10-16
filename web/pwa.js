(() => {
  const version = document.documentElement.dataset.build;
  const game = document.getElementById('game-area');
  const canvas = document.getElementById('canvas');
  const rotate = document.getElementById('rotate');
  const message = document.getElementById('web-message');
  const updateButton = document.getElementById('update');
  const fullscreenButton = document.getElementById('fullscreen');
  const loading = document.getElementById('loading');
  const progress = document.getElementById('progress');
  const subscribers = new Set();
  let registration;
  let availableVersion = '';
  let checking = false;

  function touchDevice() {
    return navigator.maxTouchPoints > 0 || matchMedia('(pointer: coarse)').matches || /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
  }

  function localCoopDevice() {
    const agent = navigator.userAgent || '';
    const platform = navigator.userAgentData?.platform || navigator.platform || '';
    const mobile = navigator.userAgentData?.mobile === true || /Android|iPhone|iPad|iPod|Mobile|Tablet|Silk|Kindle|PlayBook/i.test(agent + ' ' + platform);
    const ipadDesktop = /Macintosh|MacIntel/i.test(agent + ' ' + platform) && navigator.maxTouchPoints > 1;
    const desktop = /Windows NT|Macintosh|X11|CrOS|Linux/i.test(agent);
    return desktop && !mobile && !ipadDesktop && !matchMedia('(pointer: coarse)').matches;
  }

  function resize() {
    const bounds = game.getBoundingClientRect();
    const touch = touchDevice();
    const scale = Math.min(window.devicePixelRatio || 1, touch ? 2 : 3);
    const width = Math.max(1, Math.round(bounds.width));
    const height = Math.max(1, Math.round(bounds.height));
    const localCoop = localCoopDevice();
    const portrait = touch && !localCoop && window.innerHeight > window.innerWidth;
    rotate.hidden = !portrait;
    canvas.style.width = `${width}px`;
    canvas.style.height = `${height}px`;
    const pixelWidth = Math.round(width * scale);
    const pixelHeight = Math.round(height * scale);
    if (canvas.width !== pixelWidth) canvas.width = pixelWidth;
    if (canvas.height !== pixelHeight) canvas.height = pixelHeight;
    window.RobotDefenseWeb.metrics = {width, height, touch, localCoop, blocked: portrait};
    for (const subscriber of subscribers) subscriber(JSON.stringify(window.RobotDefenseWeb.metrics));
  }

  window.RobotDefenseWeb = {
    metrics: {},
    subscribe(callback) {
      subscribers.add(callback);
      callback(JSON.stringify(this.metrics));
    },
  };

  async function fullscreen() {
    try {
      if (!document.fullscreenElement) {
        if (!document.documentElement.requestFullscreen) throw new Error('Fullscreen unavailable');
        await document.documentElement.requestFullscreen();
      }
      if (screen.orientation?.lock) await screen.orientation.lock('landscape');
      else if (touchDevice()) message.textContent = 'Hãy xoay ngang điện thoại để chơi.';
    } catch {
      message.textContent = 'Hãy bật tự động xoay và xoay ngang điện thoại.';
    }
    resize();
    if (rotate.hidden) canvas.focus();
  }

  function showUpdate(nextVersion) {
    if (!nextVersion) return;
    if (nextVersion === version) {
      availableVersion = '';
      updateButton.hidden = true;
      if (message.textContent === 'Đã tải xong phiên bản mới.') message.textContent = '';
      return;
    }
    availableVersion = nextVersion;
    message.textContent = 'Đã tải xong phiên bản mới.';
    updateButton.hidden = false;
  }

  function queryVersion(worker, expectedVersion) {
    if (!worker) return;
    const channel = new MessageChannel();
    const timeout = setTimeout(() => channel.port1.close(), 3000);
    channel.port1.onmessage = (event) => {
      clearTimeout(timeout);
      channel.port1.close();
      if (!expectedVersion || event.data.version === expectedVersion) showUpdate(event.data.version);
    };
    worker.postMessage({type: 'GET_VERSION'}, [channel.port2]);
  }

  async function checkUpdate() {
    if (!registration || checking || document.visibilityState === 'hidden' || !navigator.onLine) return;
    checking = true;
    try {
      await registration.update();
      const response = await fetch(new URL('index.build.json', window.location.href), {cache: 'no-store'});
      if (response.ok) queryVersion(registration.active, (await response.json()).version);
    } catch {
      if (!availableVersion) message.textContent = 'Đang chơi bản đã tải; sẽ kiểm tra cập nhật khi có mạng.';
    } finally {
      checking = false;
    }
  }

  async function registerWorker() {
    if (!('serviceWorker' in navigator)) return;
    try {
      registration = await navigator.serviceWorker.register(GODOT_CONFIG.serviceWorker, {updateViaCache: 'none'});
      navigator.serviceWorker.addEventListener('message', (event) => {
        if (event.data?.type === 'UPDATE_READY') showUpdate(event.data.version);
        if (event.data?.type === 'GET_CLIENT_VERSION') event.ports[0]?.postMessage({version});
      });
      navigator.serviceWorker.addEventListener('controllerchange', () => queryVersion(navigator.serviceWorker.controller));
      checkUpdate();
    } catch {
      message.textContent = 'Chưa lưu được bản offline. Bạn vẫn có thể chơi khi có mạng.';
    }
  }

  fullscreenButton.addEventListener('click', fullscreen);
  document.getElementById('rotate-fullscreen').addEventListener('click', fullscreen);
  updateButton.addEventListener('click', () => {
    if (window.confirm('Cập nhật game? Trận đang chơi sẽ bắt đầu lại.')) window.location.reload();
  });
  window.addEventListener('resize', resize);
  window.visualViewport?.addEventListener('resize', resize);
  document.addEventListener('fullscreenchange', () => {
    fullscreenButton.textContent = document.fullscreenElement ? 'Đang toàn màn hình' : 'Toàn màn hình';
    resize();
  });
  window.addEventListener('online', checkUpdate);
  window.addEventListener('pageshow', checkUpdate);
  document.addEventListener('visibilitychange', checkUpdate);
  setInterval(checkUpdate, 60000);
  resize();
  registerWorker();
  const config = {...GODOT_CONFIG, serviceWorker: '', canvasResizePolicy: 0};
  const missing = Engine.getMissingFeatures({threads: GODOT_THREADS_ENABLED});
  if (missing.length) {
    document.getElementById('loading-message').textContent = `Trình duyệt chưa hỗ trợ: ${missing.join(', ')}. Hãy cập nhật Chrome hoặc Safari.`;
    return;
  }
  const engine = new Engine(config);
  engine.startGame({onProgress(current, total) {
    if (total > 0) {
      progress.max = total;
      progress.value = current;
    }
  }}).then(() => {
    loading.hidden = true;
    resize();
  }).catch((error) => {
    document.getElementById('loading-message').textContent = 'Chưa tải được game. Hãy kết nối mạng và mở lại trang.';
    progress.hidden = true;
    console.error(error);
  });
})();
