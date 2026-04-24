extends Area2D
class_name BloodPool

@export_category("Stats")
@export var lifetime: float = 5.0
@export var heal_per_second: float = 6.0

@export_category("References")
@export var collision_shape_path: NodePath = NodePath("CollisionShape2D")

var owner_player: Node = null
var current_lifetime: float = 0.0

func configure(player: Node, duration: float, healing_rate: float, radius: float) -> void:
    owner_player = player
    lifetime = duration
    heal_per_second = healing_rate
    current_lifetime = lifetime
    var collision_shape: CollisionShape2D = get_node_or_null(collision_shape_path)
    if collision_shape != null and collision_shape.shape is CircleShape2D:
        collision_shape.shape.radius = radius

func _process(delta: float) -> void:
    current_lifetime -= delta
    if current_lifetime <= 0.0:
        queue_free()
        return

    if owner_player != null and is_instance_valid(owner_player):
        if owner_player.global_position.distance_to(global_position) <= _get_radius():
            owner_player.health_component.heal(heal_per_second * delta * float(owner_player.stats_component.get_stat("healing_power_mult", 1.0)))

func _get_radius() -> float:
    var collision_shape: CollisionShape2D = get_node_or_null(collision_shape_path)
    if collision_shape != null and collision_shape.shape is CircleShape2D:
        return collision_shape.shape.radius
    return 24.0
