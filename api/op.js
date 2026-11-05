import { multi, K, COLLS } from './_redis.js';

const okId = id => typeof id === 'string' && id.length > 0 && id.length <= 64;
const okItem = v => v && typeof v === 'object' && okId(v.id) && JSON.stringify(v).length <= 4000;

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ error: 'Use POST' });
  try {
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : (req.body || {});
    const cmds = [];

    if (body.reset) {
      // Full replace (used by "Importar backup")
      for (const c of COLLS) {
        const items = Array.isArray(body.reset[c]) ? body.reset[c] : [];
        if (items.length > 5000 || !items.every(okItem)) return res.status(400).json({ error: 'Backup inválido' });
        cmds.push(['DEL', K[c]]);
        if (items.length) cmds.push(['HSET', K[c], ...items.flatMap(v => [v.id, JSON.stringify(v)])]);
      }
    } else {
      const ops = Array.isArray(body.ops) ? body.ops : [];
      if (!ops.length || ops.length > 500) return res.status(400).json({ error: 'Operações inválidas' });
      for (const op of ops) {
        if (!COLLS.includes(op.c)) return res.status(400).json({ error: 'Coleção inválida' });
        if (op.t === 'put' && okItem(op.v)) cmds.push(['HSET', K[op.c], op.v.id, JSON.stringify(op.v)]);
        else if (op.t === 'del' && okId(op.id)) cmds.push(['HDEL', K[op.c], op.id]);
        else return res.status(400).json({ error: 'Operação inválida' });
      }
    }

    cmds.push(['SET', K.seeded, '1']);
    cmds.push(['INCR', K.ver]);
    const out = await multi(cmds);
    res.status(200).json({ ver: Number(out[out.length - 1]) });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
