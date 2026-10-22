class_name MenuUpdates
extends VBoxContainer

var updater: GameUpdateService
var channel_choice: OptionButton
var status: Label
var version: Label
var progress_bar: ProgressBar
var action: Button
var releases: Button
var styled_state := -1


func configure(service: GameUpdateService) -> void:
	updater = service
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 20)
	var row := HBoxContainer.new()
	add_child(row)
	var current := Label.new()
	current.text = "Installiert · v" + updater.current_version
	current.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	current.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	row.add_child(current)
	channel_choice = OptionButton.new()
	channel_choice.add_item("Stable")
	channel_choice.add_item("Beta")
	MenuStyle.action(channel_choice, false, true)
	row.add_child(channel_choice)
	channel_choice.item_selected.connect(func(index: int) -> void: updater.set_channel("stable" if index == 0 else "beta"))
	version = Label.new()
	version.add_theme_font_size_override("font_size", 32)
	version.add_theme_color_override("font_color", DentiUIStyle.GOLD)
	add_child(version)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", 18)
	add_child(status)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 8
	progress_bar.show_percentage = false
	progress_bar.add_theme_stylebox_override("background", DentiUIStyle._box(DentiUIStyle.RAISED, Color.TRANSPARENT, 4, 0))
	progress_bar.add_theme_stylebox_override("fill", DentiUIStyle._box(DentiUIStyle.GOLD, Color.TRANSPARENT, 4, 0))
	add_child(progress_bar)
	action = Button.new()
	MenuStyle.action(action, true)
	add_child(action)
	action.pressed.connect(_activate)
	releases = Button.new()
	releases.text = "Release-Hinweise ↗"
	MenuStyle.action(releases, false, true)
	add_child(releases)
	releases.pressed.connect(func() -> void: OS.shell_open(UpdateRelease.RELEASES_URL))
	updater.changed.connect(refresh)
	refresh()


func _exit_tree() -> void:
	if is_instance_valid(updater) and updater.changed.is_connected(refresh): updater.changed.disconnect(refresh)


func _activate() -> void:
	match updater.state:
		GameUpdateService.State.AVAILABLE: updater.download_update()
		GameUpdateService.State.READY: updater.install_update()
		GameUpdateService.State.DOWNLOADING, GameUpdateService.State.VERIFYING: updater.cancel_download()
		_: updater.check_for_updates(true)


func refresh() -> void:
	channel_choice.select(0 if updater.channel == "stable" else 1)
	channel_choice.disabled = updater.busy()
	version.visible = not updater.available.is_empty()
	version.text = "v" + str(updater.available.get("version", ""))
	progress_bar.visible = updater.state == GameUpdateService.State.DOWNLOADING
	progress_bar.value = updater.progress
	action.disabled = updater.state in [GameUpdateService.State.CHECKING, GameUpdateService.State.INSTALLING]
	action.text = "Erneut prüfen"
	match updater.state:
		GameUpdateService.State.IDLE: status.text = "Nach Updates suchen"
		GameUpdateService.State.CHECKING: status.text = "Updates werden geprüft …"
		GameUpdateService.State.CURRENT: status.text = "Keine neuere Version verfügbar"
		GameUpdateService.State.AVAILABLE:
			status.text = "Update verfügbar · %.0f MB" % (float(updater.available.assets["windows-x86_64"].size) / 1000000.0)
			action.text = "Herunterladen"
		GameUpdateService.State.DOWNLOADING:
			status.text = "Download · %.0f %%" % updater.progress
			action.text = "Abbrechen"
		GameUpdateService.State.VERIFYING:
			status.text = "Paket wird geprüft …"
			action.text = "Abbrechen"
		GameUpdateService.State.READY:
			status.text = "Bereit zur Installation"
			action.text = "Installieren & neu starten"
		GameUpdateService.State.INSTALLING: status.text = "Neustart wird vorbereitet …"
		GameUpdateService.State.ERROR: status.text = updater.message
	if styled_state != updater.state:
		MenuStyle.action(action, not updater.busy(), updater.busy())
		MenuStyle.focus(action, action.has_focus())
		styled_state = updater.state
	status.add_theme_color_override("font_color", DentiUIStyle.CORAL if updater.state == GameUpdateService.State.ERROR else DentiUIStyle.INK)
