import fs from "node:fs";
import path from "node:path";

const file = path.resolve("./requests.json")

export async function onRequest(context, next) {
  const url = context.url.pathname;
  if (url.startsWith("/_astro/") || url.match(/\.(css|js|png|jpg|jpeg|gif|svg|ico|woff2?)$/i)) {
      return next();
    }

  try {
    let requests = 1;
    if (fs.existsSync(file)) {
      const data = JSON.parse(fs.readFileSync(file, "utf8"));
      requests = (data.requests || 0) + 1;
    }
    fs.writeFileSync(file, JSON.stringify({ requests: requests }), "utf8");

  } catch (e) {
    console.error("Something broke while spying on you:", e)
  }
  return next();
}
