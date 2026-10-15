import contextlib
import importlib.util
import io
import json
import re
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("prepare_web_pwa", ROOT / "scripts/prepare_web_pwa.py")
prepare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(prepare)


class WebBuildTests(unittest.TestCase):
    def export_fixture(self, output, revision):
        shell = (ROOT / "web/shell.html").read_text()
        config = {"executable": "index", "fileSizes": {"index.wasm": 10, "index.pck": 10}, "serviceWorker": "index.service.worker.js"}
        shell = shell.replace("$GODOT_PROJECT_NAME", "Robot Defense").replace("$GODOT_CONFIG", json.dumps(config)).replace("$GODOT_THREADS_ENABLED", "false").replace("$GODOT_URL", "index.js").replace("$GODOT_HEAD_INCLUDE", '<link rel="manifest" href="index.manifest.json">')
        (output / "index.html").write_text(shell)
        (output / "index.manifest.json").write_text(json.dumps({"name": "Robot Defense", "background_color": "#172124", "icons": [{"src": "index.512x512.png"}]}))
        for name in ("js", "wasm", "pck", "audio.worklet.js", "audio.position.worklet.js", "512x512.png", "offline.html"):
            (output / f"index.{name}").write_text(revision + name)

    def prepare(self, output):
        with patch.object(sys, "argv", ["prepare_web_pwa.py", str(output / "index.html")]), contextlib.redirect_stdout(io.StringIO()):
            prepare.main()
        return json.loads((output / "index.build.json").read_text())

    def test_versioned_files_subpath_and_repeat(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            self.export_fixture(output, "A")
            record = self.prepare(output)
            version = record["version"]
            html = (output / "index.html").read_text()
            self.assertIn(f'data-build="{version}"', html)
            self.assertIn(f'"executable":"index.{version}"', html)
            self.assertIn(f'index.{version}.wasm', html)
            self.assertNotIn('src="/', html)
            self.assertFalse((output / "index.wasm").exists())
            for name in record["files"]:
                self.assertTrue((output / name).is_file())
                self.assertTrue(name in ("index.html", "index.manifest.json") or f".{version}." in name)
            manifest = json.loads((output / "index.manifest.json").read_text())
            self.assertEqual(manifest["id"], "./index.html")
            self.assertEqual(manifest["scope"], "./")
            self.assertIn(version, manifest["icons"][0]["src"])
            self.assertEqual(self.prepare(output), record)
            self.export_fixture(output, "B")
            next_record = self.prepare(output)
            self.assertNotEqual(next_record["version"], version)
            self.assertFalse(any(f".{version}." in path.name for path in output.iterdir()))
            worker = (output / "index.service.worker.js").read_text()
            self.assertNotRegex(worker, r"__VERSION__|__FILES__")

    def test_tampered_build_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            self.export_fixture(output, "A")
            record = self.prepare(output)
            (output / f"index.{record['version']}.wasm").write_text("changed")
            with self.assertRaisesRegex(ValueError, "Build resource changed"):
                self.prepare(output)


if __name__ == "__main__":
    unittest.main()
