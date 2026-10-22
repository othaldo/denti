"""Version and package CI exports. Standard library only; no Git mutations."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = re.compile(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:[a-zA-Z][a-zA-Z0-9]*)(?:\.[a-zA-Z0-9]+)*))?")


def read_version(source):
    match = re.search(r'^config/version="([^"]+)"$', source, re.MULTILINE)
    if not match or not VERSION.fullmatch(match[1]):
        raise ValueError("project.godot must have a semantic config/version")
    return match[1]


def metadata(root, sha, ref, run_number, repository):
    if not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("a full Git commit SHA is required")
    if not re.fullmatch(r"[\w.-]+/[\w.-]+", repository):
        raise ValueError("invalid GitHub repository")
    base = read_version((root / "project.godot").read_text(encoding="utf-8"))
    tag = None
    if ref.startswith("refs/tags/"):
        tag = ref.removeprefix("refs/tags/")
        version = tag.removeprefix("v")
        if not tag.startswith("v") or not VERSION.fullmatch(version):
            raise ValueError("release tags must look like v0.6.0 or v0.6.0-beta.1")
        if version.split("-")[0] != base.split("-")[0]:
            raise ValueError("release tag and project.godot base version differ")
        channel = "beta" if "-" in version else "stable"
    else:
        if not re.fullmatch(r"[1-9]\d*", str(run_number)):
            raise ValueError("a positive GitHub run number is required")
        version = base.split("-")[0] + "-dev." + str(run_number)
        channel = "dev"
    save_source = (root / "scripts/systems/run_store.gd").read_text(encoding="utf-8")
    save_schema = re.search(r"^const VERSION := (\d+)$", save_source, re.MULTILINE)
    if not save_schema:
        raise ValueError("could not determine save schema")
    return {"schema_version": 1, "version": version, "channel": channel,
            "commit": sha, "tag": tag, "repository": repository,
            "save_schema": int(save_schema[1]),
            "built_at": datetime.now(timezone.utc).isoformat(timespec="seconds")}


def stamp(root, info):
    project = root / "project.godot"
    source = project.read_text(encoding="utf-8")
    source, versions = re.subn(r'^config/version="[^"]+"$',
                              'config/version="' + info["version"] + '"', source, flags=re.MULTILINE)
    source, builds = re.subn(r'^build="[^"]+"$',
                            'build="' + info["commit"][:7] + '"', source, flags=re.MULTILINE)
    if versions != 1 or builds != 1:
        raise ValueError("expected one version and one build stamp")
    project.write_text(source, encoding="utf-8")
    presets = root / "export_presets.cfg"
    if presets.exists():
        numeric_version = info["version"].split("-")[0] + ".0"
        export_source = presets.read_text(encoding="utf-8")
        for key in ["file_version", "product_version"]:
            export_source, count = re.subn(r'^application/' + key + r'="[^"]*"$',
                                          'application/' + key + '="' + numeric_version + '"', export_source, flags=re.MULTILINE)
            if count != 1:
                raise ValueError("expected one Windows " + key)
        presets.write_text(export_source, encoding="utf-8")
    output = root / "build/build-info.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")


def digest(path):
    # Streaming also supports Python 3.10 used by existing repository tooling.
    with path.open("rb") as source:
        result = hashlib.sha256()
        for block in iter(lambda: source.read(1024 * 1024), b""):
            result.update(block)
        return result.hexdigest()


def package(root):
    info = json.loads((root / "build/build-info.json").read_text(encoding="utf-8"))
    if not VERSION.fullmatch(info["version"]):
        raise ValueError("invalid package version")
    dist = root / "dist"
    dist.mkdir(parents=True, exist_ok=True)
    assets = {}
    checksums = []
    for platform, directory, required in [
        ("web", "web", ["index.html", "index.js", "index.wasm", "index.pck"]),
        ("windows-x86_64", "windows", ["Denti.exe", "Denti.pck"]),
    ]:
        source = root / "build" / directory
        for name in required:
            if not (source / name).is_file() or (source / name).stat().st_size == 0:
                raise ValueError("missing or empty export: " + str(source / name))
        (source / "build-info.json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
        name = "Denti-" + info["version"] + "-" + platform + ".zip"
        output = dist / name
        with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in sorted(source.rglob("*")):
                if path.is_symlink():
                    raise ValueError("export contains a symlink")
                if path.is_file():
                    archive.write(path, path.relative_to(source).as_posix())
        sha256 = digest(output)
        assets[platform] = {"name": name, "sha256": sha256, "size": output.stat().st_size,
                            "url": ("https://github.com/" + info["repository"] + "/releases/download/" + info["tag"] + "/" + name) if info["tag"] else None}
        checksums.append(sha256 + "  " + name)
    release = dict(info, assets=assets)
    manifest = dist / "release.json"
    manifest.write_text(json.dumps(release, indent=2) + "\n", encoding="utf-8")
    checksums.append(digest(manifest) + "  release.json")
    (dist / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n", encoding="utf-8")
    return release


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["stamp", "package"])
    parser.add_argument("--sha", default=os.environ.get("GITHUB_SHA", ""))
    parser.add_argument("--ref", default=os.environ.get("GITHUB_REF", ""))
    parser.add_argument("--run", default=os.environ.get("GITHUB_RUN_NUMBER", ""))
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", ""))
    args = parser.parse_args()
    if args.command == "stamp":
        info = metadata(ROOT, args.sha, args.ref, args.run, args.repository)
        stamp(ROOT, info)
        values = {"version": info["version"], "channel": info["channel"], "tag": info["tag"] or "",
                  "artifact": "denti-" + info["version"] + "-" + info["commit"][:7]}
        if os.environ.get("GITHUB_OUTPUT"):
            with open(os.environ["GITHUB_OUTPUT"], "a", encoding="utf-8") as output:
                output.write("".join(key + "=" + value + "\n" for key, value in values.items()))
        print(json.dumps(values))
    else:
        print(json.dumps(package(ROOT), indent=2))


if __name__ == "__main__":
    main()
