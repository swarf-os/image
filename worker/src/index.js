// swarf-os download page (ADR 0029, 0030).
//
// GET /                       the page: a word to type, then the current ISO, SHA256SUMS and its
//                             cosign bundle, with the commands to check them.
// GET|HEAD /<release>/<file>  a file streamed from the R2 bucket (Range supported, so a browser
//                             or curl -C - can resume a 5 GB download). No word needed here.
//
// The bucket holds one release folder, YYYYMMDD-HHMM/ (tools/r2-upload.sh writes it, then deletes
// the previous one). A release counts once its SHA256SUMS.bundle exists: it is uploaded last.

const RELEASE = /^\d{8}-\d{4}$/;
const FILE = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;
const IDENTITY = "https://github.com/swarf-os/image/.github/workflows/iso.yml@refs/heads/main";
const ISSUER = "https://token.actions.githubusercontent.com";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed\n", { status: 405, headers: { allow: "GET, HEAD" } });
    }
    if (url.pathname === "/") return page(env, request.method);
    if (url.pathname === "/robots.txt") {
      return new Response("User-agent: *\nDisallow: /\n", { headers: { "content-type": "text/plain" } });
    }
    const parts = url.pathname.slice(1).split("/");
    if (parts.length === 2 && RELEASE.test(parts[0]) && FILE.test(parts[1])) {
      return file(env, request, parts.join("/"), parts[1]);
    }
    return new Response("Not found\n", { status: 404 });
  },
};

// The newest complete release folder and its files, or null. Kept for a minute in the isolate:
// each listing is an R2 class A operation (1 M a month free), and the page is no-store.
let memo = { at: 0, value: null };
async function current(env) {
  if (Date.now() - memo.at < 60_000) return memo.value;
  memo = { at: Date.now(), value: await list(env) };
  return memo.value;
}

async function list(env) {
  const top = await env.ISO.list({ delimiter: "/" });
  const releases = top.delimitedPrefixes.map((p) => p.slice(0, -1)).filter((p) => RELEASE.test(p)).sort().reverse();
  for (const r of releases) {
    const listed = await env.ISO.list({ prefix: r + "/" });
    const files = listed.objects.map((o) => ({ name: o.key.slice(r.length + 1), size: o.size }));
    const iso = files.find((f) => f.name.endsWith(".iso"));
    if (iso && files.some((f) => f.name === "SHA256SUMS") && files.some((f) => f.name === "SHA256SUMS.bundle")) {
      return { release: r, iso };
    }
  }
  return null;
}

async function file(env, request, key, name) {
  const headers = new Headers({ "x-robots-tag": "noindex" });
  if (request.method === "HEAD") {
    const head = await env.ISO.head(key);
    if (head === null) return new Response(null, { status: 404 });
    head.writeHttpMetadata(headers);
    headers.set("etag", head.httpEtag);
    headers.set("accept-ranges", "bytes");
    headers.set("content-length", String(head.size));
    headers.set("content-disposition", `attachment; filename="${name}"`);
    return new Response(null, { headers });
  }
  let object;
  try {
    object = await env.ISO.get(key, { onlyIf: request.headers, range: request.headers });
  } catch (e) {
    // R2 rejects a range it cannot satisfy (or a malformed one) by throwing; answer 416, not 500.
    const head = request.headers.has("range") ? await env.ISO.head(key) : null;
    if (head === null) return new Response("Unavailable\n", { status: 503, headers: { "retry-after": "60" } });
    return new Response(null, { status: 416, headers: { "content-range": `bytes */${head.size}` } });
  }
  if (object === null) return new Response("Not found\n", { status: 404 });
  object.writeHttpMetadata(headers);
  headers.set("etag", object.httpEtag);
  headers.set("accept-ranges", "bytes");
  headers.set("content-disposition", `attachment; filename="${name}"`);
  if (!("body" in object)) {
    // A precondition failed: If-None-Match / If-Modified-Since mean "not modified".
    const notModified = request.headers.has("if-none-match") || request.headers.has("if-modified-since");
    return new Response(null, { status: notModified ? 304 : 412, headers });
  }
  let status = 200;
  if (request.headers.has("range") && object.range) {
    const r = object.range;
    const suffix = r.suffix !== undefined;
    const offset = suffix ? object.size - r.suffix : (r.offset ?? 0);
    const length = suffix ? r.suffix : (r.length ?? object.size - offset);
    if (offset !== 0 || length !== object.size) {
      status = 206;
      headers.set("content-range", `bytes ${offset}-${offset + length - 1}/${object.size}`);
    }
    headers.set("content-length", String(length));
  } else {
    headers.set("content-length", String(object.size));
  }
  return new Response(object.body, { status, headers });
}

async function page(env, method) {
  const cur = await current(env);
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]);
  let body;
  if (cur === null) {
    body = "<p>No ISO is published at the moment. Come back later.</p>";
  } else {
    const base = `/${cur.release}/`;
    const iso = esc(cur.iso.name);
    const gb = (cur.iso.size / 1e9).toFixed(2);
    const d = cur.release;
    body = `
<p>Built ${d.slice(0, 4)}-${d.slice(4, 6)}-${d.slice(6, 8)} from the tested image <code>ghcr.io/swarf-os/image:stable</code>.</p>
<ul>
  <li><a href="${base}${iso}">${iso}</a> (${gb} GB)</li>
  <li><a href="${base}SHA256SUMS">SHA256SUMS</a></li>
  <li><a href="${base}SHA256SUMS.bundle">SHA256SUMS.bundle</a> (cosign signature)</li>
</ul>
<p>Check the download, in the folder that holds the three files:</p>
<pre>cosign verify-blob --bundle SHA256SUMS.bundle \\
  --certificate-identity '${IDENTITY}' \\
  --certificate-oidc-issuer ${ISSUER} SHA256SUMS
sha256sum -c SHA256SUMS</pre>
<p>Write it to a USB stick with Fedora Media Writer. Personal project, no support.</p>`;
  }
  // The word below is NOT security, on purpose: it is plain text in a public repository and the
  // file links work without it. It only keeps casual visitors away while the project is not yet
  // in line with Fedora's trademark rules (SPEC, "Hosting and download page"). Nothing sensitive
  // may ever be in the ISO.
  const html = `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title>swarf-os</title>
<style>
body{font:16px/1.5 system-ui,sans-serif;max-width:42rem;margin:2rem auto;padding:0 1rem;color:#222;background:#fafafa}
pre{background:#eee;padding:.75rem;overflow-x:auto;font-size:.85rem}
input,button{font:inherit;padding:.3rem .6rem}
@media (prefers-color-scheme:dark){body{color:#ddd;background:#1b1b1b}pre{background:#2a2a2a}a{color:#8ab4f8}}
</style></head>
<body>
<h1>swarf-os</h1>
<form id="gate"><input id="word" type="password" autocomplete="off" aria-label="Word" autofocus> <button>Open</button></form>
<div id="content" hidden>${body}</div>
<script>
// Visual gate only (see the comment in worker/src/index.js).
document.getElementById("gate").addEventListener("submit", (e) => {
  e.preventDefault();
  if (document.getElementById("word").value === "fraws") {
    e.target.hidden = true;
    document.getElementById("content").hidden = false;
  }
});
</script>
</body></html>
`;
  return new Response(method === "HEAD" ? null : html, {
    headers: { "content-type": "text/html; charset=utf-8", "x-robots-tag": "noindex", "cache-control": "no-store" },
  });
}
