
extends Node2D

@export var duration: float = 5.0
@export var damage: int = 10
@export var rotation_speed: float = 5.0
@export var hit_interval: float = 0.3

var time = 0.0
var _can_hit = true

func _process(delta):
    time += delta
    rotation += rotation_speed * delta
    if time >= duration:
        queue_free()

func _on_body_entered(body):
    if body.is_in_group("enemy") and _can_hit:
        _can_hit = false
        body.take_damage(damage)
        await get_tree().create_timer(hit_interval).timeout
        _can_hit = true
