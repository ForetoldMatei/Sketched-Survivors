extends EnemyBase
class_name EnemyChaser

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player_ref == null or not is_instance_valid(player_ref):
		velocity = Vector2.ZERO
		return
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
