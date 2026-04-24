extends Control

@export_category("References")
@export var settings_panel_path: NodePath = NodePath("SettingsPanel")
@export var resolution_option_path: NodePath = NodePath("SettingsPanel/MarginContainer/VBoxContainer/ResolutionOption")
@export var volume_slider_path: NodePath = NodePath("SettingsPanel/MarginContainer/VBoxContainer/VolumeSlider")

@onready var settings_panel: PanelContainer = get_node_or_null(settings_panel_path)
@onready var resolution_option: OptionButton = get_node_or_null(resolution_option_path)
@onready var volume_slider: HSlider = get_node_or_null(volume_slider_path)

var resolutions := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

func _ready() -> void:
	if settings_panel != null:
		settings_panel.visible = false
	if resolution_option != null and resolution_option.item_count == 0:
		for resolution in resolutions:
			resolution_option.add_item("%dx%d" % [resolution.x, resolution.y])
		resolution_option.select(0)
	if volume_slider != null:
		volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))

func _on_start_button_pressed() -> void:
	Game.goto_pre_run()
func _on_settings_button_pressed() -> void:
	if settings_panel != null:
		settings_panel.visible = not settings_panel.visible

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_close_settings_button_pressed() -> void:
	if settings_panel != null:
		settings_panel.visible = false

func _on_resolution_option_item_selected(index: int) -> void:
	if index >= 0 and index < resolutions.size():
		DisplayServer.window_set_size(resolutions[index])

func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))
