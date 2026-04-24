extends CanvasLayer
class_name HUDController

@export_category("References")
@export var hp_bar_path: NodePath = NodePath("PanelRoot/MarginContainer/VBoxContainer/HpBar")
@export var hp_label_path: NodePath = NodePath("PanelRoot/MarginContainer/VBoxContainer/HpLabel")
@export var xp_bar_path: NodePath = NodePath("PanelRoot/MarginContainer/VBoxContainer/XpBar")
@export var xp_label_path: NodePath = NodePath("PanelRoot/MarginContainer/VBoxContainer/XpLabel")
@export var level_label_path: NodePath = NodePath("PanelRoot/MarginContainer/VBoxContainer/LevelLabel")
@export var wave_label_path: NodePath = NodePath("WavePanel/MarginContainer/WaveLabel")
@export var wave_flash_label_path: NodePath = NodePath("WaveClearLabel")

@export_category("Visuals")
@export var wave_flash_duration: float = 2.0

@onready var hp_bar: ProgressBar = get_node_or_null(hp_bar_path)
@onready var hp_label: Label = get_node_or_null(hp_label_path)
@onready var xp_bar: ProgressBar = get_node_or_null(xp_bar_path)
@onready var xp_label: Label = get_node_or_null(xp_label_path)
@onready var level_label: Label = get_node_or_null(level_label_path)
@onready var wave_label: Label = get_node_or_null(wave_label_path)
@onready var wave_flash_label: Label = get_node_or_null(wave_flash_label_path)

var player: Player = null

func bind_player(target: Player) -> void:
    player = target
    player.health_component.health_changed.connect(_on_health_changed)
    _on_health_changed(player.health_component.current_health, player.health_component.get_max_health())
    _refresh_xp()

func _ready() -> void:
    EventBus.xp_collected.connect(_on_xp_collected)
    EventBus.player_level_up.connect(_on_player_level_up)
    _refresh_xp()
    set_current_wave(1)
    if wave_flash_label != null:
        wave_flash_label.visible = false

func _on_health_changed(current: float, maximum: float) -> void:
    if hp_label != null:
        hp_label.text = "HP: %d / %d" % [roundi(current), roundi(maximum)]
    if hp_bar != null:
        hp_bar.max_value = maximum
        hp_bar.value = current

func _on_xp_collected(_amount: int) -> void:
    _refresh_xp()

func _on_player_level_up(_new_level: int) -> void:
    _refresh_xp()

func _refresh_xp() -> void:
    if level_label != null:
        level_label.text = "Level %d" % RunState.current_level
    if xp_label != null:
        xp_label.text = "XP: %d / %d" % [RunState.current_xp, RunState.current_xp_to_next]
    if xp_bar != null:
        xp_bar.max_value = RunState.current_xp_to_next
        xp_bar.value = RunState.current_xp

func set_current_wave(wave_index: int) -> void:
    if wave_label != null:
        wave_label.text = "Wave %d" % wave_index

func show_wave_clear_message(message: String) -> void:
    if wave_flash_label == null:
        return
    wave_flash_label.text = message
    wave_flash_label.visible = true
    wave_flash_label.modulate.a = 1.0
    var tween := create_tween()
    tween.tween_interval(maxf(0.1, wave_flash_duration * 0.6))
    tween.tween_property(wave_flash_label, "modulate:a", 0.0, wave_flash_duration * 0.4)
    tween.finished.connect(func(): wave_flash_label.visible = false)
