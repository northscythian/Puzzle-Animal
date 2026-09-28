/* Yandex Games bridge. No account login is requested by the game. */
(() => {
  const key = 'furry-builders-v2';
  let sdk = null, player = null, cached = null, cloudTimer = null;
  let sdkPause = false, adPause = false, focused = document.hasFocus();
  let readySent = false, gameplay = false, running = false;
  try { cached = JSON.parse(localStorage.getItem(key) || 'null'); } catch (_) {}
  const api = window.furryPlatform = {
    blocked: false, adPending: false, reward: false, language: 'ru', orientationBlocked: false,
    status: 'loading',
    load() { return cached?.content || ''; },
    save(content) {
      cached = {content, updated: Date.now()};
      try { localStorage.setItem(key, JSON.stringify(cached)); } catch (_) {}
      clearTimeout(cloudTimer);
      cloudTimer = setTimeout(() => {
        if (player) player.setData({furrySave: cached}).catch(() => {});
      }, 1200);
    },
    ready() {
      if (sdk && !readySent) { sdk.features.LoadingAPI.ready(); readySent = true; }
    },
    setGameplay(value) { gameplay = !!value; updatePause(); },
    setOrientationBlocked(value) { api.orientationBlocked = !!value; updatePause(); },
    rewarded() {
      api.reward = false;
      if (!sdk || api.adPending) return;
      api.adPending = true;
      adPause = true; updatePause();
      const done = () => { api.adPending = false; adPause = false; updatePause(); };
      try {
        sdk.adv.showRewardedVideo({callbacks: {
          onOpen() { adPause = true; updatePause(); },
          onRewarded() { api.reward = true; },
          onClose: done,
          onError() { api.reward = false; done(); }
        }});
      } catch (_) { done(); }
    }
  };
  function updatePause() {
    api.blocked = document.hidden || !focused || sdkPause || adPause || api.orientationBlocked;
    const active = gameplay && !api.blocked;
    if (active !== running) {
      running = active;
      const events = sdk?.features?.GameplayAPI;
      if (events) active ? events.start() : events.stop();
    }
  }
  document.addEventListener('visibilitychange', updatePause);
  window.addEventListener('blur', () => { focused = false; updatePause(); });
  window.addEventListener('focus', () => { focused = true; updatePause(); });
  document.addEventListener('contextmenu', e => e.preventDefault());
  api.boot = async () => {
    if (window.FURRY_STANDALONE) { api.status = 'standalone'; updatePause(); return; }
    if (!window.YaGames) { api.status = ['localhost','127.0.0.1'].includes(location.hostname) ? 'local-preview' : 'sdk-error'; return; }
    try {
      sdk = await YaGames.init();
      api.language = sdk.environment.i18n.lang;
      sdk.on('game_api_pause', () => { sdkPause = true; updatePause(); });
      sdk.on('game_api_resume', () => { sdkPause = false; updatePause(); });
      try {
        player = await sdk.getPlayer({scopes: false});
        const data = await player.getData(['furrySave']);
        const remote = data.furrySave;
        if (remote && typeof remote.content === 'string' && Number.isFinite(remote.updated) && (!cached || remote.updated > cached.updated)) {
          cached = remote;
          try { localStorage.setItem(key, JSON.stringify(cached)); } catch (_) {}
        }
      } catch (_) { /* Guest play remains available with browser storage. */ }
      api.status = 'yandex';
    } catch (_) { api.status = 'sdk-error'; }
    updatePause();
  };
})();
