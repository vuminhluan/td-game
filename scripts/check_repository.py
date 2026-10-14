#!/usr/bin/env python3
import hashlib
import json
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
VERSIONED = re.compile(r"(?:^|[-_])v\d+(?:$|[-_.])", re.IGNORECASE)
RESOURCE = re.compile(r'["\'](res://[^"\'\n]+)["\']')
LINK = re.compile(r'\]\(([^)\n]+)\)')
ERRORS = []
COUNTS = {"resources": 0, "links": 0, "fingerprints": 0}


def error(file, message):
    ERRORS.append(f"{file.relative_to(ROOT)}: {message}")


def project_path(value, owner):
    if value.startswith("res://"):
        return ROOT / value[6:]
    candidate = Path(value)
    if candidate.is_absolute():
        for folder in ("assets", "docs", "gd", "scripts", "scenes", "config"):
            marker = "/" + folder + "/"
            if marker in value:
                return ROOT / folder / value.split(marker, 1)[1]
        return candidate
    if value.startswith(("assets/", "docs/", "gd/", "scripts/", "scenes/", "config/")):
        return ROOT / value
    return owner.parent / candidate


def check_hash(owner, value, expected):
    file = project_path(value, owner)
    COUNTS["fingerprints"] += 1
    if not file.is_file():
        error(owner, f"missing fingerprint input {value}")
    elif hashlib.sha256(file.read_bytes()).hexdigest() != expected:
        error(owner, f"stale fingerprint for {value}; rerun its producer")


def check_json(owner, data):
    if isinstance(data, dict):
        for value, record in data.get("reference_generations", {}).items():
            check_hash(owner, value, record["sha256"])
        fingerprints = data.get("source_fingerprints", {})
        if isinstance(fingerprints, dict):
            for value, expected in fingerprints.items():
                check_hash(owner, value, expected)
        for field in ("source", "runtime", "extraction"):
            expected = data.get(field + "_sha256")
            if isinstance(expected, str) and isinstance(data.get(field), str):
                check_hash(owner, data[field], expected)
        if isinstance(data.get("sha256"), str):
            for field in ("raw", "artwork", "atlas"):
                if isinstance(data.get(field), str):
                    check_hash(owner, data[field], data["sha256"])
                    break
        for child in data.values():
            check_json(owner, child)
    elif isinstance(data, list):
        for child in data:
            check_json(owner, child)


def anchors(file):
    counts = {}
    found = set()
    for heading in re.findall(r"^#{1,6}\s+(.+?)\s*#*\s*$", file.read_text(), re.MULTILINE):
        slug = re.sub(r"[^\w\s-]", "", heading.lower()).strip().replace(" ", "-")
        suffix = counts.get(slug, 0)
        found.add(slug if suffix == 0 else f"{slug}-{suffix}")
        counts[slug] = suffix + 1
    return found


def check_markdown(file):
    for link in LINK.findall(file.read_text()):
        link = link.strip().strip("<>")
        parsed = urlsplit(link)
        if parsed.scheme or parsed.netloc:
            continue
        target = file.parent / unquote(parsed.path) if parsed.path else file
        COUNTS["links"] += 1
        if not target.exists():
            error(file, f"missing link {link}")
        elif parsed.fragment and target.suffix == ".md" and unquote(parsed.fragment) not in anchors(target):
            error(file, f"missing heading {link}")


def main():
    files = [ROOT / "README.md", ROOT / "AGENTS.md", ROOT / "project.godot", ROOT / "export_presets.cfg"]
    for folder in ("assets", "docs", "gd", "scripts", "scenes", "config", "godot_tests"):
        files.extend(path for path in (ROOT / folder).rglob("*") if path.is_file() and "__pycache__" not in path.parts)
    for file in files:
        if any(VERSIONED.search(part) for part in file.relative_to(ROOT).parts):
            error(file, "versioned asset/file path; use its current role name")
        if file.suffix in {".gd", ".tscn", ".tres", ".godot", ".cfg"}:
            for reference in RESOURCE.findall(file.read_text()):
                if "%" in reference or "*" in reference:
                    continue
                COUNTS["resources"] += 1
                if not project_path(reference, file).exists():
                    error(file, f"missing resource {reference}")
        elif file.suffix == ".md":
            check_markdown(file)
        elif file.suffix == ".json":
            try:
                check_json(file, json.loads(file.read_text()))
            except (ValueError, TypeError) as exc:
                error(file, f"invalid metadata: {exc}")
    for message in ERRORS:
        print(message, file=sys.stderr)
    print("REPOSITORY: " + ", ".join(f"{n} {label}" for label, n in COUNTS.items()) + f", {len(ERRORS)} failures")
    return bool(ERRORS)


if __name__ == "__main__":
    sys.exit(main())
