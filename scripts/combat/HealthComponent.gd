extends Node
class_name HealthComponent

signal health_changed(current: float, maximum: float)
signal died()

@export_category("References")
@export var stats_component_path: NodePath

var current_health: float = 1.0

@onready var stats_component: StatsComponent = get_node_or_null(stats_component_path)

func initialize_from_stats() -> void:
    current_health = get_max_health()
    health_changed.emit(current_health, get_max_health())

func get_max_health() -> float:
    if stats_component == null:
        return 1.0
    return maxf(1.0, float(stats_component.get_stat("max_health", 1.0)))

func take_damage(amount: float) -> void:
    current_health = maxf(0.0, current_health - amount)
    health_changed.emit(current_health, get_max_health())
    if current_health <= 0.0:
        died.emit()

func heal(amount: float) -> void:
    current_health = minf(get_max_health(), current_health + amount)
    health_changed.emit(current_health, get_max_health())
