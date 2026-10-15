import hashlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    entry = Path(sys.argv[1] if len(sys.argv) > 1 else "build/web/index.html")
    if entry.name != "index.html":
        raise ValueError("The Web shell requires an index.html entry")
    worker = entry.with_suffix(".service.worker.js")
    manifest_path = entry.with_suffix(".manifest.json")
    record_path = entry.with_suffix(".build.json")
    html = entry.read_text()
    if 'data-build="' in html:
        record = json.loads(record_path.read_text())
        for name, expected in record["files"].items():
            if hashlib.sha256((entry.parent / name).read_bytes()).hexdigest() != expected:
                raise ValueError(f"Build resource changed: {name}; export again")
        print(f"PWA: existing build {record['version']} verified")
        return
    for path in entry.parent.glob("index.*"):
        if re.fullmatch(r"index\.[a-f0-9]{20}\..+", path.name):
            path.unlink()
    for role in ("pwa.js", "pwa.css"):
        (entry.parent / f"index.{role}").write_bytes((ROOT / "web" / role).read_bytes())
    manifest = json.loads(manifest_path.read_text())
    manifest.update({"id": "./index.html", "scope": "./", "short_name": manifest["name"], "theme_color": manifest["background_color"], "prefer_related_applications": False})
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    resources = [entry] + sorted(
        path for path in entry.parent.glob("index.*")
        if path.is_file() and path not in (entry, worker, record_path)
        and path.suffix in {".html", ".js", ".css", ".wasm", ".pck", ".json", ".png"}
    )
    for suffix in (".js", ".wasm", ".pck", ".manifest.json", ".pwa.js", ".pwa.css"):
        if entry.with_suffix(suffix) not in resources:
            raise ValueError(f"Missing export resource: {entry.with_suffix(suffix)}")
    digest = hashlib.sha256()
    for path in resources:
        digest.update(path.name.encode() + b"\0" + path.read_bytes())
    template = (ROOT / "web/service-worker.js").read_text()
    digest.update(template.encode())
    version = digest.hexdigest()[:20]
    renamed = {path.name: f"index.{version}." + path.name[len("index."):] for path in resources if path not in (entry, manifest_path)}
    for path in resources:
        if path.suffix in {".html", ".js", ".css", ".json"}:
            source = path.read_text()
            for previous, replacement in sorted(renamed.items(), key=lambda item: -len(item[0])):
                source = source.replace(previous, replacement)
            if path == entry:
                source = source.replace('<html lang="vi">', f'<html lang="vi" data-build="{version}">')
                source, count = re.subn(r'"executable"\s*:\s*"index"', f'"executable":"index.{version}"', source)
                if count != 1 or f'data-build="{version}"' not in source:
                    raise ValueError("Unsupported Godot HTML/config; check the custom shell")
            path.write_text(source)
    for previous, replacement in renamed.items():
        (entry.parent / previous).rename(entry.parent / replacement)
    files = [path.name if path.name not in renamed else renamed[path.name] for path in resources]
    source = template.replace("__VERSION__", version).replace("__FILES__", json.dumps(files))
    worker.write_text(source)
    checksums = {name: hashlib.sha256((entry.parent / name).read_bytes()).hexdigest() for name in files}
    record_path.write_text(json.dumps({"version": version, "files": checksums}, indent=2) + "\n")
    total = sum((entry.parent / name).stat().st_size for name in files)
    print(f"PWA: {len(files)} versioned resources, {total / 1024 / 1024:.1f} MiB; version {version}")


if __name__ == "__main__":
    main()
