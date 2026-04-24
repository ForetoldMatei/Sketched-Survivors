extends EnemyBase
class_name EnemyCharger

enum ChargerState {
	CHASE,
	WINDUP,
	CHARGING,
	RECOVER
}

@export_category("Charger")
@export var engage_range: float = 260.0
@export var windup_duration: float = 0.5
@export var charge_speed: float = 340.0
@export var charge_duration: float = 0.55
@export var recover_duration: float = 0.4
@export var telegraph_length: float = 170.0
@export var telegraph_width: float = 8.0

var state: ChargerState = ChargerState.CHASE
var state_timer: float = 0.0
var charge_direction: Vector2 = Vector2.RIGHT

@onready var telegraph_line: Line2D = get_node_or_null("TelegraphLine")

func _ready() -> void:
	super._ready()
	if telegraph_line != null:
		telegraph_line.visible = false
		telegraph_line.width = telegraph_width

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if player_ref == null or not is_instance_valid(player_ref):
		velocity = Vector2.ZERO
		return

	state_timer = maxf(0.0, state_timer - delta)

	match state:
		ChargerState.CHASE:
			_process_chase()
		ChargerState.WINDUP:
			_process_windup()
		ChargerState.CHARGING:
			_process_charge()
		ChargerState.RECOVER:
			_process_recover()

	move_and_slide()

func _process_chase() -> void:
	var to_player = player_ref.global_position - global_position
	velocity = to_player.normalized() * move_speed
	if to_player.length() <= engage_range:
		state = ChargerState.WINDUP
		state_timer = windup_duration
		charge_direction = to_player.normalized()
		if charge_direction == Vector2.ZERO:
			charge_direction = Vector2.RIGHT
		_update_telegraph()

func _process_windup() -> void:
	velocity = Vector2.ZERO
	_update_telegraph()
	if state_timer <= 0.0:
		state = ChargerState.CHARGING
		state_timer = charge_duration
		if telegraph_line != null:
			telegraph_line.visible = false

func _process_charge() -> void:
	velocity = charge_direction * charge_speed
	if state_timer <= 0.0:
		state = ChargerState.RECOVER
		state_timer = recover_duration
		velocity = Vector2.ZERO

func _process_recover() -> void:
	velocity = Vector2.ZERO
	if state_timer <= 0.0:
		state = ChargerState.CHASE

func _update_telegraph() -> void:
	if telegraph_line == null:
		return
	telegraph_line.visible = true
	telegraph_line.width = telegraph_width
	telegraph_line.points = PackedVector2Array([Vector2.ZERO, charge_direction * telegraph_length])
