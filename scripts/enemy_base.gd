
extends CharacterBody2D

@export var speed: float = 100
@export var max_hp: int = 100
@export var contact_damage: int = 10
@export var contact_interval: float = 0.5
@export var modifier_chance: float = 0.3

var current_hp: int
var _damage_loop_running = false

func _ready():
    current_hp = max_hp
    apply_modifier()

func _on_hitbox_body_entered(body):
    if body.is_in_group("player"):
        body.take_damage(contact_damage)
        if not _damage_loop_running:
            _start_damage_loop(body)

func _start_damage_loop(body):
    _damage_loop_running = true
    while is_instance_valid(body) and body.is_in_group("player"):
        await get_tree().create_timer(contact_interval).timeout
        if not is_instance_valid(body):
            break
        body.take_damage(contact_damage)
    _damage_loop_running = false

func apply_modifier():
    if randf() > modifier_chance:
        return

    var roll = randi() % 3
    match roll:
        0:
            speed *= 1.4
            modulate = Color(0.4,0.6,1)
        1:
            contact_damage *= 1.5
            modulate = Color(1,0.3,0.3)
        2:
            max_hp *= 2
            current_hp = max_hp
            modulate = Color(0.3,1,0.3)
