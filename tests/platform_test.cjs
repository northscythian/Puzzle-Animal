const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const source = fs.readFileSync('web/platform.js', 'utf8');

async function scenario(mode) {
  const handlers = {};
  const stored = new Map();
  let readyCount = 0, cloudSave, starts = 0, stops = 0;
  const sdk = {
    environment: {i18n: {lang: 'ru'}},
    features: {LoadingAPI: {ready() { readyCount++; }}, GameplayAPI: {start() { starts++; }, stop() { stops++; }}},
    on(event, callback) { handlers[event] = callback; },
    async getPlayer() { return {async getData() {return {};}, async setData(data) {cloudSave = data;}}; },
    adv: {showRewardedVideo({callbacks}) {
      callbacks.onOpen();
      if (mode === 'reward') callbacks.onRewarded();
      if (mode === 'error') callbacks.onError(); else callbacks.onClose();
    }}
  };
  const context = {console, Date, Number, setTimeout, clearTimeout,
    location: {hostname: 'localhost'},
    localStorage: {getItem: key => stored.get(key), setItem: (key,value) => stored.set(key,value)},
    document: {hidden:false, hasFocus:()=>true, addEventListener:(e,f)=>{handlers[e]=f;}},
    addEventListener:(e,f)=>{handlers[e]=f;}, YaGames: {init:async()=>sdk}};
  context.window = context;
  vm.createContext(context);
  vm.runInContext(source, context);
  const api = context.furryPlatform;
  await api.boot();
  assert.equal(api.status, 'yandex');
  api.ready(); api.ready(); assert.equal(readyCount,1);
  api.setGameplay(true); assert.equal(starts,1);
  api.setOrientationBlocked(true); assert.equal(api.blocked,true); assert.equal(stops,1);
  api.setOrientationBlocked(false); assert.equal(starts,2);
  api.save('[company]\nmoney=1200');
  assert.equal(api.load(),'[company]\nmoney=1200');
  await new Promise(resolve=>setTimeout(resolve,1250));
  assert.equal(cloudSave.furrySave.content,api.load());
  handlers.blur(); assert.equal(api.blocked,true);
  handlers.focus(); assert.equal(api.blocked,false);
  handlers.game_api_pause(); handlers.blur(); handlers.game_api_resume();
  assert.equal(api.blocked,true); handlers.focus(); assert.equal(api.blocked,false);
  api.rewarded(); assert.equal(api.adPending,false);
  assert.equal(api.reward,mode==='reward'); assert.equal(api.blocked,false);
  context.FURRY_STANDALONE = true;
  delete context.YaGames;
  vm.runInContext(source, context);
  await context.furryPlatform.boot();
  assert.equal(context.furryPlatform.status,'standalone');
  context.furryPlatform.rewarded();
  assert.equal(context.furryPlatform.reward,false);
}
(async()=>{for(const mode of ['reward','closed','error']) await scenario(mode);console.log('PLATFORM PASSED: SDK ready once, local/cloud saves, overlapping pause, ad reward/close/error');})().catch(error=>{console.error(error);process.exitCode=1;});
