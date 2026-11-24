import base64, hashlib, pathlib, re, sys, urllib.request

ROOT = pathlib.Path(r"C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business")
ASSETS = ROOT / "Assets"
PROXY = "http://127.0.0.1:7897"
EMBED = re.compile(r"!\[([^\]]*)\]\((https?://[^)\s]+|data:image/[^)]+)\)")
EXT = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp", "image/gif": ".gif"}

opener = urllib.request.build_opener(
    urllib.request.ProxyHandler({"http": PROXY, "https": PROXY})
)

changed = 0
for f in sorted(ROOT.rglob("*.md")):
    if any(p.startswith(".") for p in f.relative_to(ROOT).parts):
        continue
    text = f.read_text(encoding="utf-8")
    if not EMBED.search(text):
        continue

    def repl(m):
        global changed
        alt, url = m.group(1), m.group(2)
        try:
            if url.startswith("data:"):
                header, b64 = url.split(",", 1)
                mime = header.split(";")[0][5:]
                data = base64.b64decode(b64)
            else:
                req = urllib.request.Request(
                    url, headers={"User-Agent": "Mozilla/5.0", "Referer": url.split("/")[0] + "//" + url.split("/")[2] + "/"}
                )
                with opener.open(req, timeout=60) as r:
                    data = r.read()
                    mime = (r.headers.get("Content-Type") or "image/jpeg").split(";")[0]
        except Exception as e:
            print("  FAIL", f.name, url[:60], type(e).__name__, e)
            return m.group(0)
        ext = EXT.get(mime, ".jpg")
        name = hashlib.md5(data).hexdigest() + ext
        dst = ASSETS / name
        if not dst.exists():
            dst.write_bytes(data)
        changed += 1
        print("  SAVED", f.name, name, len(data))
        return f"![[{name}]]"

    new = EMBED.sub(repl, text)
    if new != text and "--write" in sys.argv:
        f.write_text(new, encoding="utf-8")

print("embeds converted:", changed, "write:", "--write" in sys.argv)
