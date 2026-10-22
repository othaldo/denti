"""Compose stable and development Pages content from verified build archives."""

import argparse
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import urllib.error
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MAX_UNPACKED = 1024 * 1024 * 1024


class GitHub:
    def __init__(self, repository, token):
        if not re.fullmatch(r"[\w.-]+/[\w.-]+", repository):
            raise ValueError("invalid GitHub repository")
        self.base = "https://api.github.com/repos/" + repository + "/"
        self.token = token

    def read(self, path, binary=False, missing=False):
        url = self.base + path
        request = urllib.request.Request(url, headers={
            "User-Agent": "Denti-Pages", "Accept": "application/octet-stream" if binary else "application/vnd.github+json"})
        # A redirect to GitHub's download host must not carry the API credential.
        if self.token:
            request.add_unredirected_header("Authorization", "Bearer " + self.token)
        try:
            with urllib.request.urlopen(request, timeout=120) as response:
                content = response.read()
        except urllib.error.HTTPError as error:
            if missing and error.code == 404:
                return None
            raise
        return content if binary else json.loads(content)


def web_package(manifest, payload):
    asset = manifest["assets"]["web"]
    name = asset["name"]
    if Path(name).name != name or not name.endswith("-web.zip"):
        raise ValueError("invalid web asset name")
    if len(payload) != asset["size"] or hashlib.sha256(payload).hexdigest() != asset["sha256"]:
        raise ValueError("web archive checksum or size differs")
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        info = json.loads(archive.read("build-info.json"))
        if any(info.get(key) != manifest.get(key) for key in ["version", "commit", "channel"]):
            raise ValueError("web archive and release identity differ")
        for name in ["index.html", "index.js", "index.wasm", "index.pck"]:
            if archive.getinfo(name).file_size == 0:
                raise ValueError("empty web export file: " + name)
    return manifest, payload


def local_dev(directory):
    manifest = json.loads((directory / "release.json").read_text(encoding="utf-8"))
    name = manifest["assets"]["web"]["name"]
    if Path(name).name != name:
        raise ValueError("invalid web asset name")
    if manifest.get("channel") != "dev":
        raise ValueError("only a development build can replace /dev/")
    return web_package(manifest, (directory / name).read_bytes())


def stable_release(client):
    release = client.read("releases/latest", missing=True)
    if release is None:
        return None
    if release["draft"] or release["prerelease"]:
        raise ValueError("latest stable release is not published stable content")
    assets = {entry["name"]: entry for entry in release["assets"]}
    manifest_asset = assets.get("release.json")
    if manifest_asset is None:
        raise ValueError("published release lacks release.json")
    manifest = json.loads(client.read("releases/assets/" + str(manifest_asset["id"]), binary=True))
    if manifest.get("channel") != "stable" or manifest.get("tag") != release["tag_name"] or "v" + manifest.get("version", "") != release["tag_name"]:
        raise ValueError("stable release tag and manifest differ")
    asset = assets[manifest["assets"]["web"]["name"]]
    return web_package(manifest, client.read("releases/assets/" + str(asset["id"]), binary=True))


def latest_dev(client):
    runs = client.read("actions/workflows/build.yml/runs?branch=main&event=push&status=success&per_page=5")
    for run in runs["workflow_runs"]:
        artifacts = client.read("actions/runs/" + str(run["id"]) + "/artifacts?per_page=100")
        for artifact in artifacts["artifacts"]:
            if artifact["expired"] or not artifact["name"].startswith("denti-"):
                continue
            payload = client.read("actions/artifacts/" + str(artifact["id"]) + "/zip", binary=True)
            with zipfile.ZipFile(io.BytesIO(payload)) as archive:
                manifest = json.loads(archive.read("release.json"))
                if manifest.get("channel") != "dev" or manifest.get("commit") != run["head_sha"]:
                    raise ValueError("development artifact identity differs from its workflow run")
                return web_package(manifest, archive.read(manifest["assets"]["web"]["name"]))
    return None


def extract_web(package, target):
    manifest, payload = package
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        if sum(entry.file_size for entry in archive.infolist()) > MAX_UNPACKED:
            raise ValueError("web archive exceeds unpacked size limit")
        seen = set()
        for entry in archive.infolist():
            name = PurePosixPath(entry.filename)
            if name.is_absolute() or ".." in name.parts or "\\" in entry.filename or ":" in entry.filename or not name.parts or name.parts[0] in ["dev", ".git"]:
                raise ValueError("unsafe or reserved archive path")
            if stat.S_ISLNK(entry.external_attr >> 16) or entry.filename in seen:
                raise ValueError("symlink or duplicate archive entry")
            seen.add(entry.filename)
        archive.extractall(target)
    (target / "release.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def compose(output, stable, dev):
    if stable is None and dev is None:
        raise ValueError("there is no build to deploy")
    # Always create a new site. Never merge old, possibly stale exported files.
    output.mkdir(parents=True, exist_ok=False)
    extract_web(stable or dev, output)
    development = output / "dev"
    development.mkdir()
    if dev is not None:
        extract_web(dev, development)
    else:
        development.joinpath("index.html").write_text(
            '<!doctype html><html lang="de"><meta charset="utf-8"><title>Denti</title>'
            '<h1>Denti</h1><p>Zurzeit ist kein Testbuild verfügbar.</p>'
            '<a href="../">Veröffentlichte Version spielen</a></html>', encoding="utf-8")
    (output / ".nojekyll").touch()
    print("Pages root:", (stable or dev)[0]["version"], "| /dev/:", dev[0]["version"] if dev else "unavailable")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dev-dist", type=Path)
    parser.add_argument("--require-stable", action="store_true")
    args = parser.parse_args()
    client = GitHub(os.environ.get("GITHUB_REPOSITORY", ""), os.environ.get("GH_TOKEN", ""))
    stable = stable_release(client)
    if args.require_stable and stable is None:
        raise ValueError("publish a stable GitHub release before deploying it")
    dev = local_dev(args.dev_dist) if args.dev_dist else latest_dev(client)
    compose(ROOT / "build/site", stable, dev)


if __name__ == "__main__":
    main()
