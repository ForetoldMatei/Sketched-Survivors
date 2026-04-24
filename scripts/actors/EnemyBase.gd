extends CharacterBody2D
class_name EnemyBase

const XP_ORB_SCENE = preload("res://scenes/run/XpOrb.tscn")

@export_category("References")
@export var hitbox_path: NodePath = NodePath("Hitbox")
@export var body_visual_path: NodePath = NodePath("SketchVisual")

@export_category("Stats")
@export var move_speed: float = 90.0
@export var max_health: float = 24.0
@export var contact_damage: float = 8.0
@export var contact_interval: float = 0.5
@export var xp_value: int = 1

var current_health: float = 24.0
var player_ref: Node = null
var contact_timers: Dictionary = {}

@onready var hitbox: Area2D = get_node_or_null(hitbox_path)
@onready var body_visual: Node2D = get_node_or_null(body_visual_path)

func _ready() -> void:
    current_health = max_health
    add_to_group("enemies")

func _physics_process(delta: float) -> void:
    _refresh_player_reference()
    _update_contact_timers(delta)
    _process_contact_overlaps()

func _refresh_player_reference() -> void:
    if player_ref == null or not is_instance_valid(player_ref):
        player_ref = get_tree().get_first_node_in_group("player")

func take_damage(amount: float, killer: Node = null) -> void:
    current_health -= amount
    if current_health <= 0.0:
        _die(killer)

func _die(killer: Node) -> void:
    RunState.record_kill()
    EventBus.enemy_died.emit(self, killer, global_position)
    var orb := XP_ORB_SCENE.instantiate()
    orb.global_position = global_position
    orb.xp_amount = xp_value
    get_tree().current_scene.get_node("PickupLayer").add_child(orb)
    queue_free()


func _process_contact_overlaps() -> void:
    if hitbox == null:
        return
    for body in hitbox.get_overlapping_bodies():
        if not body.is_in_group("player"):
            continue
        var body_id := body.get_instance_id()
        if contact_timers.has(body_id):
            continue
        _deal_contact_damage(body)

func _deal_contact_damage(body: Node) -> void:
    if body == null or not is_instance_valid(body):
        return
    if not body.is_in_group("player") or not body.has_method("take_damage"):
        return
    body.take_damage(contact_damage)
    contact_timers[body.get_instance_id()] = contact_interval

func _update_contact_timers(delta: float) -> void:
    var ids := contact_timers.keys()
    for body_id in ids:
        contact_timers[body_id] = float(contact_timers[body_id]) - delta
        if float(contact_timers[body_id]) <= 0.0:
            contact_timers.erase(body_id)

func _on_hitbox_body_entered(body: Node) -> void:
    if not body.is_in_group("player"):
        return
    var body_id := body.get_instance_id()
    if contact_timers.has(body_id):
        return
    _deal_contact_damage(body)

func _on_hitbox_body_exited(body: Node) -> void:
    if body == null:
        return
    contact_timers.erase(body.get_instance_id())
