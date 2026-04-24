extends Area2D
class_name ProjectileBase

@export_category("References")
@export var collision_shape_path: NodePath = NodePath("CollisionShape2D")
@export var visual_root_path: NodePath = NodePath("SketchVisual")
@export var splash_ring_path: NodePath = NodePath("SplashRing")

@export_category("Bounce")
@export var chain_search_radius: float = 340.0
@export var bounce_retarget_offset: float = 6.0

var owner_actor: Node
var runtime_skill: RuntimeSkill
var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var remaining_lifetime: float = 1.0
var damage: float = 10.0
var splash_radius: float = 0.0
var pierce_remaining: int = 0
var bounce_remaining: int = 0
var hit_targets: Array[Node] = []

@onready var collision_shape: CollisionShape2D = get_node_or_null(collision_shape_path)
@onready var visual_root: Node2D = get_node_or_null(visual_root_path)
@onready var splash_ring: Node2D = get_node_or_null(splash_ring_path)

func initialize(owner: Node, skill: RuntimeSkill, shoot_direction: Vector2, stats_component: StatsComponent) -> void:
	owner_actor = owner
	runtime_skill = skill
	direction = shoot_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	speed = float(skill.get_value("speed", 400.0)) * float(stats_component.get_stat("projectile_speed_mult", 1.0))
	remaining_lifetime = float(skill.get_value("lifetime", 1.0))
	damage = float(skill.get_value("damage", 10.0)) * float(stats_component.get_stat("projectile_damage_mult", 1.0))
	splash_radius = float(skill.get_value("splash_radius", 0.0)) * float(stats_component.get_stat("area_mult", 1.0))
	pierce_remaining = int(skill.get_value("pierce", 0))
	bounce_remaining = int(skill.get_value("bounce", 0)) + int(round(stats_component.get_stat("projectile_bounce", 0.0)))
	rotation = direction.angle()
	if collision_shape != null:
		var shape := collision_shape.shape as CircleShape2D
		if shape != null:
			shape.radius = float(skill.get_value("radius", 7.0))
	if splash_ring != null:
		splash_ring.visible = splash_radius > 0.0
		if splash_ring.visible:
			splash_ring.scale = Vector2.ONE * maxf(0.8, splash_radius / 16.0)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == owner_actor or hit_targets.has(body):
		return
	if not body.is_in_group("enemies"):
		return

	hit_targets.append(body)
	if splash_radius > 0.0:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.global_position.distance_to(global_position) <= splash_radius and enemy.has_method("take_damage"):
				enemy.take_damage(damage, owner_actor)
	elif body.has_method("take_damage"):
		body.take_damage(damage, owner_actor)

	if bounce_remaining > 0 and _retarget_to_next_enemy(body):
		bounce_remaining -= 1
		return

	if pierce_remaining > 0:
		pierce_remaining -= 1
	else:
		queue_free()

func _retarget_to_next_enemy(last_enemy: Node) -> bool:
	var nearest_enemy: Node = null
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == last_enemy or hit_targets.has(enemy):
			continue
		var enemy_distance = last_enemy.global_position.distance_to(enemy.global_position)
		if enemy_distance > chain_search_radius:
			continue
		if enemy_distance < nearest_distance:
			nearest_distance = enemy_distance
			nearest_enemy = enemy
	if nearest_enemy == null:
		return false
	direction = (nearest_enemy.global_position - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	rotation = direction.angle()
	global_position += direction * bounce_retarget_offset
	return true
