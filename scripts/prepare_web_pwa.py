import hashlib
import json
import re
import sys
from pathlib import Path


def replace_once(source, pattern, replacement):
    result, count = re.subn(pattern, lambda _: replacement, source)
    if count != 1:
        raise ValueError(f"Expected one match for {pattern}, got {count}")
    return result


def main():
    entry = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web/index.html")
    worker = entry.with_suffix(".service.worker.js")
    manifest_path = entry.with_suffix(".manifest.json")
    manifest = json.loads(manifest_path.read_text())
    manifest["id"] = "./" + entry.name
    manifest["short_name"] = manifest["name"]
    manifest["theme_color"] = manifest["background_color"]
    manifest["prefer_related_applications"] = False
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    resources = [entry] + sorted(
        path for path in entry.parent.glob(entry.stem + ".*")
        if path.is_file() and path not in (entry, worker)
        and path.suffix in {".html", ".js", ".wasm", ".pck", ".json", ".png"}
    )
    for suffix in (".js", ".wasm", ".pck", ".manifest.json", ".offline.html"):
        if entry.with_suffix(suffix) not in resources:
            raise ValueError(f"Missing export resource: {entry.with_suffix(suffix)}")
    digest = hashlib.sha256()
    for path in resources:
        digest.update(path.name.encode() + b"\0" + path.read_bytes())
    source = worker.read_text()
    source = replace_once(source, r"const CACHE_VERSION = [^;]+;", f"const CACHE_VERSION = '{digest.hexdigest()}';")
    source = replace_once(source, r"const CACHED_FILES = \[[^;]*\];", "const CACHED_FILES = " + json.dumps([path.name for path in resources]) + ";")
    source = replace_once(source, r"const CACHEABLE_FILES = \[[^;]*\];", "const CACHEABLE_FILES = [];")
    source = replace_once(source, r"let cached = await cache\.match\((?:event\.request|isNavigate \? CACHED_FILES\[0\] : event\.request)\);", "let cached = await cache.match(isNavigate ? CACHED_FILES[0] : event.request);")
    worker.write_text(source)
    total = sum(path.stat().st_size for path in resources)
    print(f"PWA: {len(resources)} resources cached together, {total / 1024 / 1024:.1f} MiB; version {digest.hexdigest()[:12]}")


if __name__ == "__main__":
    main()
