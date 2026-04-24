extends Node2D
class_name RunRoot

const PLAYER_SCENE = preload("res://scenes/actors/player/Player.tscn")
const ENEMY_GRUNT_SCENE = preload("res://scenes/actors/enemies/EnemyChaser.tscn")
const ENEMY_CHARGER_SCENE = preload("res://scenes/actors/enemies/EnemyCharger.tscn")

@export_category("References")
@export var actor_layer_path: NodePath = NodePath("ActorLayer")
@export var projectile_layer_path: NodePath = NodePath("ProjectileLayer")
@export var pickup_layer_path: NodePath = NodePath("PickupLayer")
@export var effect_layer_path: NodePath = NodePath("EffectLayer")
@export var enemy_spawn_timer_path: NodePath = NodePath("EnemySpawnTimer")
@export var hud_path: NodePath = NodePath("HUD")
@export var levelup_panel_path: NodePath = NodePath("HUD/LevelUpPanel")
@export var game_over_label_path: NodePath = NodePath("HUD/GameOverLabel")

@export_category("Spawn")
@export var player_spawn_position: Vector2 = Vector2(640, 360)
@export var spawn_distance_min: float = 360.0
@export var spawn_distance_max: float = 520.0
@export var inter_wave_delay: float = 1.0
@export var wave_clear_message_duration: float = 2.0
@export var wave_definitions: Array[Dictionary] = [
    {"wave": 1, "grunt": 4, "charger": 0},
    {"wave": 2, "grunt": 5, "charger": 0},
    {"wave": 3, "grunt": 6, "charger": 1},
    {"wave": 4, "grunt": 7, "charger": 1},
    {"wave": 5, "grunt": 8, "charger": 2},
    {"wave": 6, "grunt": 10, "charger": 2},
    {"wave": 7, "grunt": 11, "charger": 3},
    {"wave": 8, "grunt": 12, "charger": 4},
    {"wave": 9, "grunt": 14, "charger": 4},
    {"wave": 10, "grunt": 16, "charger": 5}
]

@onready var actor_layer: Node = get_node_or_null(actor_layer_path)
@onready var projectile_layer: Node = get_node_or_null(projectile_layer_path)
@onready var pickup_layer: Node = get_node_or_null(pickup_layer_path)
@onready var effect_layer: Node = get_node_or_null(effect_layer_path)
@onready var enemy_spawn_timer: Timer = get_node_or_null(enemy_spawn_timer_path)
@onready var hud: HUDController = get_node_or_null(hud_path)
@onready var levelup_panel: LevelUpPanel = get_node_or_null(levelup_panel_path)
@onready var game_over_label: Label = get_node_or_null(game_over_label_path)

var player: Player
var current_wave_index: int = 0
var enemies_left_to_spawn: Array[StringName] = []
var active_enemies: int = 0
var run_finished: bool = false
var wave_transition_pending: bool = false

func _ready() -> void:
    randomize()
    RunState.reset_for_new_run()
    player = PLAYER_SCENE.instantiate()
    player.class_id = RunState.selected_class_id
    player.global_position = player_spawn_position
    actor_layer.add_child(player)
    if hud != null:
        hud.bind_player(player)
    if levelup_panel != null:
        levelup_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
        levelup_panel.choice_selected.connect(_on_levelup_choice_selected)
    EventBus.player_level_up.connect(_on_player_level_up)
    EventBus.player_died.connect(_on_player_died)
    EventBus.enemy_died.connect(_on_enemy_died)
    if game_over_label != null:
        game_over_label.visible = false
    _start_wave(0)

func _exit_tree() -> void:
    if EventBus.player_level_up.is_connected(_on_player_level_up):
        EventBus.player_level_up.disconnect(_on_player_level_up)
    if EventBus.player_died.is_connected(_on_player_died):
        EventBus.player_died.disconnect(_on_player_died)
    if EventBus.enemy_died.is_connected(_on_enemy_died):
        EventBus.enemy_died.disconnect(_on_enemy_died)

func _process(_delta: float) -> void:
    if RunState.is_levelup_pending and levelup_panel != null and not levelup_panel.visible:
        _open_levelup_panel()

func _on_enemy_spawn_timer_timeout() -> void:
    if player == null or not is_instance_valid(player) or run_finished:
        return
    if enemies_left_to_spawn.is_empty():
        enemy_spawn_timer.stop()
        return
    var enemy_type: StringName = enemies_left_to_spawn.pop_front()
    var enemy: Node = null
    if enemy_type == &"charger":
        enemy = ENEMY_CHARGER_SCENE.instantiate()
    else:
        enemy = ENEMY_GRUNT_SCENE.instantiate()
    enemy.global_position = _get_spawn_position_around_player()
    actor_layer.add_child(enemy)
    active_enemies += 1
    if enemies_left_to_spawn.is_empty():
        enemy_spawn_timer.stop()

func _get_spawn_position_around_player() -> Vector2:
    var angle := randf() * TAU
    var distance := randf_range(spawn_distance_min, spawn_distance_max)
    return player.global_position + Vector2.RIGHT.rotated(angle) * distance

func _on_player_level_up(_new_level: int) -> void:
    pass

func _open_levelup_panel() -> void:
    get_tree().paused = true
    EventBus.run_paused.emit(true)
    levelup_panel.set_choices(ContentDB.get_levelup_modifier_choices(player.class_id))
    levelup_panel.visible = true

func _on_levelup_choice_selected(modifier_id: StringName) -> void:
    if player != null and is_instance_valid(player):
        player.apply_modifier(modifier_id)
    RunState.is_levelup_pending = false
    levelup_panel.visible = false
    get_tree().paused = false
    EventBus.run_paused.emit(false)

func _on_player_died() -> void:
    enemy_spawn_timer.stop()
    run_finished = true
    if game_over_label != null:
        game_over_label.visible = true
        game_over_label.text = "Run Over\nPress Enter to restart"

func _on_enemy_died(enemy: Node, _killer: Node, _death_position: Vector2) -> void:
    if enemy != null and enemy.is_in_group("enemies"):
        active_enemies = max(0, active_enemies - 1)
    if run_finished or wave_transition_pending:
        return
    if active_enemies == 0 and enemies_left_to_spawn.is_empty():
        wave_transition_pending = true
        _advance_after_wave_clear()

func _advance_after_wave_clear() -> void:
    if current_wave_index >= wave_definitions.size() - 1:
        run_finished = true
        if hud != null:
            hud.show_wave_clear_message("All waves cleared!")
        if game_over_label != null:
            game_over_label.visible = true
            game_over_label.text = "Victory!\nPress Enter to restart"
        EventBus.wave_completed.emit(current_wave_index + 1)
        return
    var next_wave_number := current_wave_index + 2
    EventBus.wave_cleared.emit(next_wave_number)
    if hud != null:
        hud.show_wave_clear_message("Wave cleared! Advancing to wave %d" % next_wave_number)
    await get_tree().create_timer(maxf(0.1, wave_clear_message_duration)).timeout
    if run_finished:
        return
    wave_transition_pending = false
    _start_wave(current_wave_index + 1)

func _start_wave(wave_index: int) -> void:
    wave_transition_pending = false
    current_wave_index = wave_index
    enemies_left_to_spawn.clear()
    active_enemies = 0
    var wave_def: Dictionary = wave_definitions[wave_index]
    for _i in range(int(wave_def.get("grunt", 0))):
        enemies_left_to_spawn.append(&"grunt")
    for _j in range(int(wave_def.get("charger", 0))):
        enemies_left_to_spawn.append(&"charger")
    enemies_left_to_spawn.shuffle()
    if hud != null:
        hud.set_current_wave(int(wave_def.get("wave", wave_index + 1)))
    EventBus.wave_started.emit(int(wave_def.get("wave", wave_index + 1)))
    await get_tree().create_timer(maxf(0.05, inter_wave_delay)).timeout
    if run_finished:
        return
    enemy_spawn_timer.start()

func _unhandled_input(event: InputEvent) -> void:
    if game_over_label != null and game_over_label.visible and event.is_action_pressed("ui_accept"):
        Game.restart_run()
