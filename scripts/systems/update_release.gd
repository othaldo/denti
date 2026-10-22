class_name UpdateRelease
extends RefCounted

const REPOSITORY := "othaldo/denti"
const DOWNLOAD_ROOT := "https://github.com/" + REPOSITORY + "/releases/download/"
const RELEASES_URL := "https://github.com/" + REPOSITORY + "/releases"
const MAX_PACKAGE_SIZE := 512 * 1024 * 1024
const PACKAGE_FILES := ["Denti.exe", "Denti.pck", "build-info.json"]


static func candidate(releases: Array, channel: String) -> Dictionary:
	var selected: Dictionary = {}
	for value in releases:
		if not value is Dictionary: continue
		var release: Dictionary = value
		if release.get("draft", true) or not release.get("published_at") is String: continue
		if channel == "stable" and release.get("prerelease", true): continue
		var tag: String = str(release.get("tag_name", ""))
		if not tag.begins_with("v") or ReleaseVersion.parse(tag.substr(1)).is_empty(): continue
		if selected.is_empty() or ReleaseVersion.compare(tag.substr(1), str(selected.tag_name).substr(1)) > 0:
			selected = release
	return selected


static func asset(release: Dictionary, name: String) -> Dictionary:
	var values: Variant = release.get("assets", [])
	if not values is Array: return {}
	for value in values:
		if value is Dictionary and value.get("name") == name: return value
	return {}


static func manifest_url(release: Dictionary) -> String:
	var tag := str(release.get("tag_name", ""))
	var entry := asset(release, "release.json")
	var expected := DOWNLOAD_ROOT + tag + "/release.json"
	return expected if str(entry.get("browser_download_url", "")) == expected else ""


static func validate(manifest: Dictionary, release: Dictionary, save_schema: int) -> String:
	var tag := str(release.get("tag_name", ""))
	var version := str(manifest.get("version", ""))
	if not _integer(manifest.get("schema_version")) or int(manifest.schema_version) != 1 or str(manifest.get("repository")) != REPOSITORY:
		return "Das Updateformat wird nicht unterstützt."
	if ReleaseVersion.parse(version).is_empty() or tag != "v" + version or str(manifest.get("tag")) != tag:
		return "Die Versionsdaten passen nicht zur Veröffentlichung."
	var expected_channel := "beta" if "-" in version else "stable"
	if str(manifest.get("channel")) != expected_channel or bool(release.get("prerelease", false)) != (expected_channel == "beta"):
		return "Der Updatekanal passt nicht zur Veröffentlichung."
	if not RegEx.create_from_string("^[0-9a-f]{40}$").search(str(manifest.get("commit", ""))):
		return "Die Buildkennung fehlt."
	if not _integer(manifest.get("save_schema")) or int(manifest.save_schema) != save_schema:
		return "Diese Version benötigt ein anderes Speicherformat. Bitte die Release-Hinweise lesen."
	var assets: Variant = manifest.get("assets", {})
	if not assets is Dictionary or not assets.get("windows-x86_64") is Dictionary:
		return "Für Windows ist kein Updatepaket vorhanden."
	var package: Dictionary = assets["windows-x86_64"]
	var name := "Denti-%s-windows-x86_64.zip" % version
	var published := asset(release, name)
	var expected_url := DOWNLOAD_ROOT + tag + "/" + name
	if str(package.get("name")) != name or str(package.get("url")) != expected_url or str(published.get("browser_download_url")) != expected_url:
		return "Die Downloadadresse passt nicht zur Veröffentlichung."
	var size: Variant = package.get("size", 0)
	if not _integer(size) or size <= 0 or size > MAX_PACKAGE_SIZE or not _integer(published.get("size")) or int(size) != int(published.size):
		return "Die Paketgröße ist ungültig."
	var checksum := str(package.get("sha256", ""))
	if not RegEx.create_from_string("^[0-9a-f]{64}$").search(checksum):
		return "Die Prüfsumme fehlt."
	var github_digest := str(published.get("digest", "")) if published.get("digest") != null else ""
	if not github_digest.is_empty() and github_digest != "sha256:" + checksum:
		return "Die Prüfsummen der Veröffentlichung stimmen nicht überein."
	return ""


static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == int(value)
