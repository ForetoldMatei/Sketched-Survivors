
extends CharacterBody2D

@export var speed: float = 200
var player

func _physics_process(delta):
    if player == null:
        return

    var dir = (player.global_position - global_position).normalized()
    velocity = dir * speed
    move_and_slide()

    if has_node("Sprite2D"):
        $Sprite2D.flip_h = dir.x < 0
