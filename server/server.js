// Relay global con historial corto: reenvía a todos y entrega los últimos mensajes al conectarse.
const { WebSocketServer } = require('ws');
const port = process.env.PORT || 8080;
const wss = new WebSocketServer({ port, maxPayload: 8 * 1024 * 1024 });
const seen = new Set(); let history = [];
wss.on('connection', (ws) => {
  history.forEach((h) => ws.send(h));
  ws.on('message', (data) => {
    const raw = data.toString(); let m; try { m = JSON.parse(raw); } catch { return; }
    if (!m.id || seen.has(m.id)) return;
    seen.add(m.id); if (seen.size > 5000) seen.clear();
    if (m.k !== 2) { history.push(raw); if (history.length > 50) history.shift(); } // k=2: ubicación, no se guarda
    for (const c of wss.clients) if (c !== ws && c.readyState === 1) c.send(raw);
  });
});
console.log('Malla server en puerto', port);
