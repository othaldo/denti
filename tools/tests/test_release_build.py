"""Release identity, runnable archive layout, and stable/dev separation."""

import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

TOOLS = Path(__file__).resolve().parents[1]


def load_tool(name):
    spec = importlib.util.spec_from_file_location(name, TOOLS / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


build = load_tool("release_build")
pages = load_tool("prepare_pages")
SHA = "a" * 40


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.project = self.root / "project.godot"
        self.project.write_text('[application]\nconfig/version="0.5.0"\n[denti]\nbuild="dev"\n', encoding="utf-8")
        (self.root / "export_presets.cfg").write_text('application/file_version="0.5.0.0"\napplication/product_version="0.5.0.0"\n', encoding="utf-8")
        store = self.root / "scripts/systems/run_store.gd"
        store.parent.mkdir(parents=True)
        store.write_text("const VERSION := 1\n", encoding="utf-8")

    def tearDown(self):
        self.temporary.cleanup()

    def info(self, ref="refs/heads/main"):
        return build.metadata(self.root, SHA, ref, "123", "othaldo/denti")

    def packaged(self, ref="refs/heads/main"):
        info = self.info(ref)
        build.stamp(self.root, info)
        for directory, files in [("web", ["index.html", "index.js", "index.wasm", "index.pck"]),
                                 ("windows", ["Denti.exe", "Denti.pck"])]:
            target = self.root / "build" / directory
            target.mkdir(parents=True, exist_ok=True)
            for name in files:
                (target / name).write_bytes(b"fixture export " + name.encode())
        return build.package(self.root)

    def test_branch_build_has_traceable_development_identity(self):
        info = self.info()
        self.assertEqual((info["version"], info["channel"], info["tag"]), ("0.5.0-dev.123", "dev", None))
        build.stamp(self.root, info)
        self.assertIn('config/version="0.5.0-dev.123"', self.project.read_text())
        self.assertIn('build="aaaaaaa"', self.project.read_text())
        self.assertEqual((self.root / "export_presets.cfg").read_text().count('="0.5.0.0"'), 2)
        self.assertEqual(json.loads((self.root / "build/build-info.json").read_text())["save_schema"], 1)

    def test_stable_and_prerelease_tags_keep_separate_channels(self):
        stable = self.info("refs/tags/v0.5.0")
        beta = self.info("refs/tags/v0.5.0-beta.1")
        self.assertEqual((stable["version"], stable["channel"]), ("0.5.0", "stable"))
        self.assertEqual((beta["version"], beta["channel"]), ("0.5.0-beta.1", "beta"))
        for ref in ["refs/tags/v0.6.0", "refs/tags/vnonsense", "refs/tags/v0.5.0/../../bad"]:
            with self.subTest(ref=ref), self.assertRaises(ValueError):
                self.info(ref)

    def test_packages_start_at_export_root_and_manifest_matches_every_byte(self):
        release = self.packaged("refs/tags/v0.5.0")
        for platform in ["web", "windows-x86_64"]:
            asset = release["assets"][platform]
            path = self.root / "dist" / asset["name"]
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), asset["sha256"])
            self.assertEqual(path.stat().st_size, asset["size"])
            self.assertIn("/releases/download/v0.5.0/", asset["url"])
            with zipfile.ZipFile(path) as archive:
                self.assertIn("build-info.json", archive.namelist())
                self.assertIn("Denti.exe" if platform == "windows-x86_64" else "index.html", archive.namelist())
                self.assertFalse(any(name.startswith("build/") for name in archive.namelist()))
        sums = (self.root / "dist/SHA256SUMS.txt").read_text().splitlines()
        for line in sums:
            checksum, name = line.split("  ")
            self.assertEqual(build.digest(self.root / "dist" / name), checksum)

    def test_empty_or_missing_export_cannot_be_released(self):
        self.packaged()
        (self.root / "build/windows/Denti.pck").write_bytes(b"")
        with self.assertRaises(ValueError):
            build.package(self.root)

    def test_development_update_cannot_overwrite_stable_root(self):
        release = self.packaged("refs/tags/v0.5.0")
        stable = pages.web_package(release, (self.root / "dist" / release["assets"]["web"]["name"]).read_bytes())
        self.project.write_text('[application]\nconfig/version="0.6.0"\n[denti]\nbuild="dev"\n')
        self.packaged()
        dev = pages.local_dev(self.root / "dist")
        output = self.root / "site"
        pages.compose(output, stable, dev)
        self.assertEqual(json.loads((output / "build-info.json").read_text())["version"], "0.5.0")
        self.assertEqual(json.loads((output / "dev/build-info.json").read_text())["version"], "0.6.0-dev.123")
        self.assertTrue((output / ".nojekyll").exists())
        with self.assertRaises(FileExistsError):
            pages.compose(output, stable, dev)

    def test_first_deployment_keeps_original_play_url_working(self):
        self.packaged()
        dev = pages.local_dev(self.root / "dist")
        output = self.root / "site"
        pages.compose(output, None, dev)
        self.assertEqual((output / "index.html").read_bytes(), (output / "dev/index.html").read_bytes())

    def test_expired_development_download_does_not_block_stable(self):
        release = self.packaged("refs/tags/v0.5.0")
        stable = pages.web_package(release, (self.root / "dist" / release["assets"]["web"]["name"]).read_bytes())
        output = self.root / "site"
        pages.compose(output, stable, None)
        self.assertIn("Veröffentlichte Version", (output / "dev/index.html").read_text(encoding="utf-8"))
        self.assertEqual(json.loads((output / "build-info.json").read_text())["channel"], "stable")

    def test_tampered_archive_and_mismatched_identity_fail(self):
        release = self.packaged()
        path = self.root / "dist" / release["assets"]["web"]["name"]
        with self.assertRaises(ValueError):
            pages.web_package(release, path.read_bytes() + b"tampered")
        release["version"] = "0.9.0"
        with self.assertRaises(ValueError):
            pages.web_package(release, path.read_bytes())

    def test_archive_cannot_escape_site_or_replace_development_route(self):
        release = self.packaged()
        path = self.root / "dist" / release["assets"]["web"]["name"]
        for unsafe in ["../outside.txt", "/absolute.txt", "dev/index.html", "C:\\outside.txt", ".git/config"]:
            payload = io.BytesIO(path.read_bytes())
            with zipfile.ZipFile(payload, "a") as archive:
                archive.writestr(unsafe, "unsafe")
            output = self.root / ("site" + str(len(list(self.root.glob("site*")))))
            output.mkdir()
            with self.subTest(path=unsafe), self.assertRaises(ValueError):
                pages.extract_web((release, payload.getvalue()), output)
        self.assertFalse((self.root / "outside.txt").exists())

    def test_prerelease_cannot_replace_stable_site(self):
        class FakeGitHub:
            def read(self, *args, **kwargs):
                return {"draft": False, "prerelease": True}
        with self.assertRaises(ValueError):
            pages.stable_release(FakeGitHub())


if __name__ == "__main__":
    unittest.main()
