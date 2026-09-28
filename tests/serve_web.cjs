// Local-only static preview; intentionally does not simulate real Yandex ads.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(process.argv[2] || 'build/yandex');
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript','.wasm':'application/wasm','.png':'image/png','.pck':'application/octet-stream'};
http.createServer((req,res)=>{
  const pathname = decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  if(pathname==='/sdk.js'){res.writeHead(200,{'Content-Type':'text/javascript'});res.end('/* Local preview: Yandex SDK is provided by the platform. */');return;}
  const file = path.resolve(root,'.'+(pathname==='/'?'/index.html':pathname));
  if(!file.startsWith(root+path.sep)||!fs.existsSync(file)||!fs.statSync(file).isFile()){res.writeHead(404);res.end();return;}
  res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
  fs.createReadStream(file).pipe(res);
}).listen(8765,'127.0.0.1',()=>console.log('Preview http://127.0.0.1:8765'));
