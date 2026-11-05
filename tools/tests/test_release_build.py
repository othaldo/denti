"""Release identity, runnable archive layout, and stable/dev separation."""

import hashlib
from http.server import BaseHTTPRequestHandler, HTTPServer
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import threading
import unittest
from unittest.mock import patch
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

    def test_github_artifact_redirect_and_release_asset_negotiate_correct_media_types(self):
        requests = []
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def do_GET(self):
                requests.append((self.path, self.headers.get("Accept"), self.headers.get("Authorization")))
                expected = "application/octet-stream" if self.path.startswith("/releases/assets/") else "application/vnd.github+json"
                if self.headers.get("Accept") != expected:
                    self.send_error(415)
                elif self.path == "/actions/artifacts/7/zip":
                    self.send_response(302)
                    self.send_header("Location", "/download/artifact.zip")
                    self.end_headers()
                else:
                    self.send_response(200)
                    self.end_headers()
                    self.wfile.write(b"PK-fixture" if self.path == "/download/artifact.zip" else b'{"id": 7}')

        with HTTPServer(("127.0.0.1", 0), Handler) as server:
            worker = threading.Thread(target=server.serve_forever, daemon=True)
            worker.start()
            try:
                client = pages.GitHub("othaldo/denti", "fixture-token")
                client.base = "http://127.0.0.1:" + str(server.server_port) + "/"
                self.assertEqual(client.read("actions/artifacts/7/zip", binary=True), b"PK-fixture")
                self.assertEqual(client.read("releases/assets/7", binary=True), b'{"id": 7}')
                self.assertEqual(client.read("actions/artifacts/7"), {"id": 7})
            finally:
                server.shutdown()
                worker.join()
        self.assertEqual(requests, [
            ("/actions/artifacts/7/zip", "application/vnd.github+json", "Bearer fixture-token"),
            ("/download/artifact.zip", "application/vnd.github+json", None),
            ("/releases/assets/7", "application/octet-stream", "Bearer fixture-token"),
            ("/actions/artifacts/7", "application/vnd.github+json", "Bearer fixture-token"),
        ])

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
        for unsafe in ["../outside.txt", "/absolute.txt", "dev/index.html", "preview/index.html", "C:\\outside.txt", ".git/config"]:
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

    def preview_fixture(self):
        release = self.packaged("refs/heads/feat/element-reactions")
        payload = (self.root / "dist" / release["assets"]["web"]["name"]).read_bytes()
        artifact = io.BytesIO()
        with zipfile.ZipFile(artifact, "w") as archive:
            archive.writestr("release.json", json.dumps(release))
            archive.writestr(release["assets"]["web"]["name"], payload)
        return (release, payload), artifact.getvalue()

    def preview_run(self, run_id=1, branch="feat/element-reactions", **overrides):
        return {"id": run_id, "head_branch": branch, "event": "push", "head_sha": SHA,
                "head_repository": {"full_name": "othaldo/denti"},
                "repository": {"full_name": "othaldo/denti"}, **overrides}

    def preview_client(self, runs, payload, expired=False, deleted=False):
        class FakeGitHub:
            def read(self, path, **kwargs):
                if path.startswith("actions/workflows/"):
                    return {"workflow_runs": runs}
                if path.startswith("git/ref/heads/"):
                    return None if deleted else {"ref": "refs/heads/feat/element-reactions"}
                if path.startswith("actions/runs/"):
                    return {"artifacts": [{"id": 7, "name": "denti-preview", "expired": expired}]}
                if path == "actions/artifacts/7/zip":
                    return payload
                raise AssertionError("Unexpected request: " + path)
        return FakeGitHub()

    def test_branch_previews_leave_stable_and_main_content_intact(self):
        self.packaged("refs/tags/v0.5.0")
        stable_manifest = json.loads((self.root / "dist/release.json").read_text())
        stable = pages.web_package(stable_manifest, (self.root / "dist" / stable_manifest["assets"]["web"]["name"]).read_bytes())
        preview, payload = self.preview_fixture()
        previews = pages.latest_previews(self.preview_client([self.preview_run()], payload))
        output = self.root / "site"
        pages.compose(output, stable, preview, previews)
        self.assertEqual(json.loads((output / "release.json").read_text())["channel"], "stable")
        self.assertEqual(json.loads((output / "dev/release.json").read_text())["commit"], SHA)
        slug = pages.preview_slug("feat/element-reactions")
        self.assertEqual((output / "preview" / slug / "index.wasm").read_bytes(), b"fixture export index.wasm")
        self.assertIn(slug + "/", (output / "preview/index.html").read_text())
        self.assertIn("feat/element-reactions", (output / "preview/index.html").read_text())

    def test_latest_success_per_branch_and_only_same_repository_builds_are_used(self):
        _, payload = self.preview_fixture()
        runs = [self.preview_run(branch="feat/pr", event="pull_request"),
                self.preview_run(branch="feat/fork", head_repository={"full_name": "fork/denti"}),
                self.preview_run(branch="main"), self.preview_run(branch="v0.5.0"),
                self.preview_run(2), self.preview_run(1),
                self.preview_run(3, branch="feat-other", event="workflow_dispatch"),
                self.preview_run(4, branch="feat"),
                self.preview_run(5, branch="feature/class-foundation"),
                self.preview_run(6, branch="feature-other", event="workflow_dispatch"),
                self.preview_run(7, branch="feature")]
        client = self.preview_client(runs, payload)
        with patch.object(client, "read", wraps=client.read) as read:
            self.assertEqual(set(pages.latest_previews(client)),
                             {"feat/element-reactions", "feat-other", "feat", "feature/class-foundation", "feature-other", "feature"})
        calls = [call.args[0] for call in read.call_args_list]
        self.assertNotIn("actions/runs/1/artifacts?per_page=100&page=1", calls)
        self.assertNotIn("git/ref/heads/feat/pr", calls)
        self.assertNotIn("git/ref/heads/feat/fork", calls)

    def test_expired_missing_or_deleted_preview_is_omitted(self):
        package, payload = self.preview_fixture()
        for kwargs in [{"expired": True}, {"deleted": True}, {"payload": None}]:
            values = {"payload": payload, **kwargs}
            with self.subTest(kwargs=kwargs):
                client = self.preview_client([self.preview_run()], **values)
                self.assertEqual(pages.latest_previews(client), {})
        output = self.root / "site"
        pages.compose(output, package, None, {})
        self.assertIn("keine Branch-Testbuilds", (output / "preview/index.html").read_text(encoding="utf-8"))

    def test_preview_with_wrong_commit_or_repository_cannot_be_published(self):
        _, payload = self.preview_fixture()
        for overrides in [{"head_sha": "b" * 40},
                          {"repository": {"full_name": "other/denti"}, "head_repository": {"full_name": "other/denti"}}]:
            with self.subTest(overrides=overrides), self.assertRaises(ValueError):
                pages.latest_previews(self.preview_client([self.preview_run(**overrides)], payload))

    def test_deleted_branch_page_is_removed_while_other_previews_remain(self):
        package, payload = self.preview_fixture()
        deleted, kept = "feature/removed", "feat/kept"
        client = self.preview_client([self.preview_run(1, deleted), self.preview_run(2, kept)], payload)
        original = client.read
        def read(path, **kwargs):
            if path == "git/ref/heads/" + deleted:
                return None
            return original(path, **kwargs)
        client.read = read
        with patch.object(client, "read", wraps=client.read) as requests:
            previews = pages.latest_previews(client)
        self.assertEqual(set(previews), {kept})
        self.assertNotIn("actions/runs/1/artifacts?per_page=100&page=1",
                         [call.args[0] for call in requests.call_args_list])
        output = self.root / "site"
        pages.compose(output, None, package, previews)
        self.assertFalse((output / "preview" / pages.preview_slug(deleted)).exists())
        self.assertTrue((output / "preview" / pages.preview_slug(kept) / "index.html").is_file())
        index = (output / "preview/index.html").read_text()
        self.assertNotIn(deleted, index)
        self.assertIn(kept, index)
        self.assertEqual((output / "index.html").read_bytes(), (output / "dev/index.html").read_bytes())

    def test_preview_discovery_paginates_past_main_builds(self):
        _, payload = self.preview_fixture()
        client = self.preview_client([self.preview_run()], payload)
        original = client.read
        def read(path, **kwargs):
            if path == "actions/workflows/build.yml/runs?status=success&per_page=100&page=1":
                return {"workflow_runs": [self.preview_run(branch="main")] * 100}
            return original(path, **kwargs)
        client.read = read
        self.assertEqual(set(pages.latest_previews(client)), {"feat/element-reactions"})

    def test_preview_names_cannot_collide_or_escape_and_labels_are_escaped(self):
        branches = ["feat/a-b", "feat-a/b", "feat/A-B", "feat/../../escape", "feat/" + "a" * 100,
                    "feat/" + "a" * 100 + "b", "feat/<script>"]
        slugs = [pages.preview_slug(branch) for branch in branches]
        self.assertEqual(len(set(slugs)), len(slugs))
        for slug in slugs:
            self.assertRegex(slug, r"^[a-z0-9-]+$")
            self.assertLessEqual(len(slug), 69)
        package, _ = self.preview_fixture()
        output = self.root / "site"
        pages.compose(output, None, package, {"feat/<script>": package})
        index = (output / "preview/index.html").read_text()
        self.assertIn("feat/&lt;script&gt;", index)
        self.assertNotIn("feat/<script>", index)

    def test_preview_alone_cannot_become_the_stable_or_main_build(self):
        package, _ = self.preview_fixture()
        with self.assertRaises(ValueError):
            pages.compose(self.root / "site", None, None, {"feat/example": package})


if __name__ == "__main__":
    unittest.main()
