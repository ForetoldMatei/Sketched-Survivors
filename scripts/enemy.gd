
extends CharacterBody2D

@export var speed = 100
@export var contact_damage = 10
@export var contact_interval = 0.5
@export var modifier_chance = 0.3

var player
var _loop = false

func _ready():
    apply_modifier()

func _physics_process(delta):
    if player == null:
        return

    var dir = (player.global_position - global_position).normalized()
    velocity = dir * speed
    move_and_slide()

    if has_node("Sprite2D"):
        $Sprite2D.flip_h = dir.x < 0

func _on_body_entered(body):
    if body.is_in_group("player"):
        body.take_damage(contact_damage)
        if not _loop:
            damage_loop(body)

func damage_loop(body):
    _loop = true
    while is_instance_valid(body):
        await get_tree().create_timer(contact_interval).timeout
        if not is_instance_valid(body):
            break
        body.take_damage(contact_damage)
    _loop = false

func apply_modifier():
    if randf() > modifier_chance:
        return

    var r = randi() % 3
    match r:
        0:
            speed *= 1.4
            modulate = Color.BLUE
        1:
            contact_damage *= 1.5
            modulate = Color.RED
        2:
            modulate = Color.GREEN
