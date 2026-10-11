#!/usr/bin/env python3
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def install(run: Path, target: Path) -> None:
    request = json.loads((run / "request.json").read_text())
    target.mkdir(parents=True, exist_ok=True)
    records = {}
    for name, spec in request["assets"].items():
        source = run / spec["source"]
        image = Image.open(source).convert("RGBA")
        size = tuple(spec["size"])
        source_bbox = image.getchannel("A").getbbox()
        if source_bbox is None:
            raise ValueError(f"{name}: empty source")
        if spec["transparent"]:
            if image.getchannel("A").getextrema()[0] == 255:
                raise ValueError(f"{name}: source has no transparency; use sprite-gen cutout first")
            subject = image.crop(source_bbox)
            margin = spec.get("margin", 2)
            ratio = min((size[0] - margin * 2) / subject.width,
                        (size[1] - margin * 2) / subject.height)
            fitted = (round(subject.width * ratio), round(subject.height * ratio))
            subject = subject.convert("RGBa").resize(fitted, Image.Resampling.LANCZOS).convert("RGBA")
            image = Image.new("RGBA", size)
            image.paste(subject, ((size[0] - fitted[0]) // 2, (size[1] - fitted[1]) // 2))
        else:
            image = image.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")
        image.save(target / f"{name}.png", optimize=True)
        records[name] = {
            "source": str(source.relative_to(ROOT)),
            "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "runtime": str((target / f"{name}.png").relative_to(ROOT)),
            "size": size,
            "source_alpha_bbox": source_bbox,
            "runtime_alpha_bbox": image.getchannel("A").getbbox(),
            "alpha_extrema": image.getchannel("A").getextrema(),
        }
    (target / "manifest.json").write_text(json.dumps({
        "version": 1, "type": "static-map-art", "generator": request["generator"],
        "source_request": str((run / "request.json").relative_to(ROOT)),
        "logical_tile_size": 40, "assets": records,
    }, indent=2) + "\n")
    print(f"Published {len(records)} static textures to {target.relative_to(ROOT)}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Publish static map images from request.json; never modify generated sources.\n\nRun with a Python environment providing Pillow. This only normalizes size and\npacks transparent silhouettes; it does not invent or repaint artwork.\n')
    parser.add_argument("--run-dir", type=Path, required=True)
    parser.add_argument("--target", type=Path, required=True)
    args = parser.parse_args()
    install(args.run_dir.resolve(), args.target.resolve())
