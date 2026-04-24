
extends Node2D

@export var duration = 5.0
@export var damage = 10
@export var rotation_speed = 5.0

var time = 0.0

func _process(delta):
    time += delta
    rotation += rotation_speed * delta
    if time > duration:
        queue_free()
