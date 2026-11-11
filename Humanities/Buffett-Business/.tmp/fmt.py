import re, sys, pathlib

ROOT = pathlib.Path(r"C:\Users\Lenovo\OneDrive\Atlas\Humanities\Buffett-Business")
IMG = re.compile(r"^!\[[^\]]*\]\(.+\)$|^!\[\[.+\]\]$")
SEP = re.compile(r"^-{3,}$")
WRITE = "--write" in sys.argv


def is_sep(s):
    return bool(SEP.match(s.strip()))


def is_img(s):
    return bool(IMG.match(s.strip()))


def head_of(block):
    """Index of first non-image, non-empty line = module heading."""
    for i, l in enumerate(block):
        if l.strip() and not is_img(l):
            return i
    return -1


def transform(blocks):
    """blocks: list of non-blank line lists (separators excluded). Return list of modules."""
    # 1. merge leading image-only block into the next block's heading position
    modules = []
    pending = []
    for b in blocks:
        if head_of(b) < 0:          # image-only block
            pending.extend(b)
            continue
        modules.append(pending + b)
        pending = []
    if pending:
        modules.append(pending)
    # 2. hoist each module's images directly under its heading
    out = []
    for b in modules:
        h = head_of(b)
        if h < 0:
            out.append(b)
            continue
        imgs = [l for l in b if is_img(l)]
        rest = [l for l in b if not is_img(l)]
        out.append([rest[0]] + imgs + rest[1:])
    return out


def render(modules, trailing_newline):
    parts = []
    for m in modules:
        while m and not m[-1].strip():
            m = m[:-1]
        parts.append("\n".join(m))
    body = "\n\n---\n\n".join(parts)
    return body + ("\n" if trailing_newline else "")


def split_blocks(text):
    lines = text.split("\n")
    blocks, cur = [], []
    for l in lines:
        if is_sep(l):
            blocks.append(cur)
            cur = []
        else:
            cur.append(l)
    blocks.append(cur)
    clean = []
    for b in blocks:
        c = [l.rstrip() for l in b if l.strip()]
        if c:
            clean.append(c)
    return clean


def nonblank(text):
    return sum(1 for l in text.split("\n") if l.strip() and not is_sep(l))


stats = {"files": 0, "changed": 0, "skipped": []}
for f in sorted(ROOT.rglob("*.md")):
    if any(p.startswith(".") for p in f.relative_to(ROOT).parts):
        continue
    stats["files"] += 1
    text = f.read_text(encoding="utf-8")
    before, after = nonblank(text), None
    new = render(transform(split_blocks(text)), text.endswith("\n"))
    after = nonblank(new)
    if before != after:
        stats["skipped"].append((f.name, before, after))
        continue
    if new != text:
        stats["changed"] += 1
        print("FIX", f.name)
        if WRITE:
            f.write_text(new, encoding="utf-8")

print(f"files={stats['files']} changed={stats['changed']} skipped={len(stats['skipped'])}")
for s in stats["skipped"]:
    print("  SKIP", s)
