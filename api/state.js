import { cmd, multi, pipeline, K, parseHash } from './_redis.js';

const DEFAULT_CHANNELS = ['Instagram', 'Projec-jr', 'Projeguinho', 'TikTok', 'Blog', 'LinkedIn'];

async function seedOnce() {
  const first = await cmd(['SET', K.seeded, '1', 'NX']);
  if (first !== 'OK') return;
  const args = [];
  DEFAULT_CHANNELS.forEach((name, i) => {
    const id = 'c' + i + Math.random().toString(36).slice(2, 8);
    args.push(id, JSON.stringify({ id, name, order: i }));
  });
  await multi([['HSET', K.channels, ...args], ['INCR', K.ver]]);
}

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  try {
    await seedOnce();
    const [ver, ch, pe, po] = await pipeline([
      ['GET', K.ver],
      ['HGETALL', K.channels],
      ['HGETALL', K.people],
      ['HGETALL', K.posts],
    ]);
    res.status(200).json({
      ver: Number(ver || 0),
      channels: parseHash(ch),
      people: parseHash(pe),
      posts: parseHash(po),
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
