import { cmd, K } from './_redis.js';

// Cheap endpoint polled by every open tab. Briefly cached at the edge so
// many devices polling at once cost only ~1 database read per second.
export default async function handler(req, res) {
  try {
    const v = await cmd(['GET', K.ver]);
    res.setHeader('Cache-Control', 'public, max-age=0, s-maxage=1');
    res.status(200).json({ ver: Number(v || 0) });
  } catch (e) {
    res.setHeader('Cache-Control', 'no-store');
    res.status(500).json({ error: e.message });
  }
}
