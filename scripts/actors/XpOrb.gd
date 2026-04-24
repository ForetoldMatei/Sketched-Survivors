extends Area2D
class_name XpOrb

@export_category("Stats")
@export var xp_amount: int = 1
@export var move_speed: float = 180.0
@export var homing_range: float = 120.0

func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var direction = player.global_position - global_position
	if direction.length() <= float(player.stats_component.get_stat("pickup_radius", 52.0)):
		RunState.add_xp(xp_amount)
		queue_free()
		return
	if direction.length() < homing_range:
		global_position += direction.normalized() * move_speed * delta
