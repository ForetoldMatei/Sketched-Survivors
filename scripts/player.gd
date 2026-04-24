
extends CharacterBody2D

@export var speed = 200.0
@export var max_hp = 100
@export var camera_limits = Rect2(Vector2(-500,-500), Vector2(1000,1000))

var current_hp = 100
var lifesteal = 0.0
var xp_multiplier = 1.0
var damage_multiplier = 1.0
var dash_cooldown = 1.0

func _physics_process(delta):
    var dir = Vector2.ZERO
    dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
    dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

    velocity = dir.normalized() * speed
    move_and_slide()

    global_position.x = clamp(global_position.x, camera_limits.position.x, camera_limits.end.x)
    global_position.y = clamp(global_position.y, camera_limits.position.y, camera_limits.end.y)

func take_damage(dmg):
    current_hp -= dmg
