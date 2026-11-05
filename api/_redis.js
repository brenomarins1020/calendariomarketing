// Minimal Upstash Redis REST client (no dependencies)
const BASE = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL;
const TOKEN = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN;

async function call(path, body) {
  if (!BASE || !TOKEN) throw new Error('Banco de dados não configurado');
  const r = await fetch(BASE + path, {
    method: 'POST',
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const j = await r.json();
  if (!r.ok) throw new Error(j.error || `Redis HTTP ${r.status}`);
  return j;
}
const unwrap = arr => arr.map(x => { if (x.error) throw new Error(x.error); return x.result; });

export const cmd = async c => { const j = await call('', c); if (j.error) throw new Error(j.error); return j.result; };
export const pipeline = async cmds => unwrap(await call('/pipeline', cmds));
export const multi = async cmds => unwrap(await call('/multi-exec', cmds));

export const K = {
  ver: 'cal:ver',
  seeded: 'cal:seeded',
  channels: 'cal:channels',
  people: 'cal:people',
  posts: 'cal:posts',
};
export const COLLS = ['channels', 'people', 'posts'];

export const parseHash = flat => {
  const out = [];
  for (let i = 0; i < (flat || []).length; i += 2) {
    try { out.push(JSON.parse(flat[i + 1])); } catch {}
  }
  return out;
};
