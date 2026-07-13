// Nightly refresh: pull recent posts for each vetted handle via Instagram Graph
// business_discovery, write posts.json consumed by index.html.
// Env: IG_USER_ID (our IG business account id), IG_ACCESS_TOKEN (long-lived user token).
import { writeFileSync } from "node:fs";

const HANDLES = [
  "baileytennisfootwork","maciej_ryszczuk_rehsport","piattitenniscenter","mytenniscoaching",
  "elabiertoclub","karuesell","sportsciencelab","sventennis","equeliteferrero","4slamtennis",
  "btt_academy","stanwawrinka85","fucsovicsmarci","murphycassone","coshannessy",
  "yutakanakamura_","built4tennis","borussiaduesseldorf","dimaovtcharov","moregardhtruls",
  "hugocalderano","felix.lebrun","kinoshita_meister","mhtabletennis","rodri_ovide",
  "guspratto","gabyreca","m3padelacademy","tapia","mariano_amat"
];

const { IG_USER_ID, IG_ACCESS_TOKEN } = process.env;
if (!IG_USER_ID || !IG_ACCESS_TOKEN) { console.error("Missing IG_USER_ID / IG_ACCESS_TOKEN"); process.exit(1); }

const out = { generated_at: new Date().toISOString(), accounts: {} };
let ok = 0, fail = 0;

for (const h of HANDLES) {
  const fields = `business_discovery.username(${h}){media.limit(3){permalink,media_type,timestamp}}`;
  const url = `https://graph.facebook.com/v21.0/${IG_USER_ID}?fields=${encodeURIComponent(fields)}&access_token=${IG_ACCESS_TOKEN}`;
  try {
    const r = await fetch(url);
    const j = await r.json();
    const media = j?.business_discovery?.media?.data;
    if (Array.isArray(media) && media.length) {
      out.accounts[h] = media.map(m => m.permalink).filter(Boolean);
      ok++; console.log(`ok   ${h}: ${media.length} posts`);
    } else {
      fail++; console.log(`skip ${h}: ${j?.error?.message || "no media (not a business/creator account?)"}`);
    }
  } catch (e) { fail++; console.log(`err  ${h}: ${e.message}`); }
  await new Promise(res => setTimeout(res, 1200)); // gentle pacing
}

writeFileSync(new URL("../posts.json", import.meta.url), JSON.stringify(out, null, 1));
console.log(`done: ${ok} ok, ${fail} skipped. posts.json written.`);
