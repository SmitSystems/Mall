// Service worker: permite instalar la app y abrirla sin Internet (red primero, caché como respaldo).
const C='malla-v6',F=['./','index.html','manifest.webmanifest','icons/icon-192.png','icons/icon-512.png','icons/icon-maskable-512.png','icons/apple-touch-icon.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(C).then(c=>Promise.allSettled(F.map(u=>c.add(u)))).then(()=>self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==C).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{if(e.request.method!=='GET'||!e.request.url.startsWith(self.location.origin))return;
 e.respondWith(fetch(e.request).then(r=>{const c=r.clone();caches.open(C).then(x=>x.put(e.request,c));return r}).catch(()=>caches.match(e.request).then(r=>r||caches.match('index.html'))))});
self.addEventListener('notificationclick',e=>{e.notification.close();e.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(l=>l.length?l[0].focus():clients.openWindow('./')))});
self.addEventListener('push',e=>{let d={};try{const j=e.data.json();d=j.data||j}catch(x){}
 e.waitUntil(clients.matchAll({type:'window',includeUncontrolled:true}).then(l=>{if(l.some(c=>c.visibilityState==='visible'))return;
  return self.registration.showNotification(d.title||'Malla',{body:d.body||'Nuevo mensaje',icon:'icons/icon-192.png',badge:'icons/icon-192.png',tag:'malla-'+(d.pin||''),renotify:true,vibrate:[120,60,120]})}))});
