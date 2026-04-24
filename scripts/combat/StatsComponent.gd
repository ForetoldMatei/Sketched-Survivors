extends Node
class_name StatsComponent

signal stats_recalculated()

@export_category("Defaults")
@export var fallback_base_stats: Dictionary = {}

var base_stats: Dictionary = {}
var resolved_stats: Dictionary = {}
var stat_bonuses: Dictionary = {}

func _ready() -> void:
    if not fallback_base_stats.is_empty() and base_stats.is_empty():
        set_base_stats(fallback_base_stats)

func set_base_stats(stats: Dictionary) -> void:
    base_stats = stats.duplicate(true)
    recalculate()

func apply_stat_modifier(stat_name: String, operation: String, value: float) -> void:
    if not stat_bonuses.has(stat_name):
        stat_bonuses[stat_name] = []
    stat_bonuses[stat_name].append({
        "operation": operation,
        "value": value
    })
    recalculate()

func recalculate() -> void:
    resolved_stats = base_stats.duplicate(true)
    for stat_name in stat_bonuses.keys():
        if not resolved_stats.has(stat_name):
            resolved_stats[stat_name] = 0.0
        for bonus in stat_bonuses[stat_name]:
            match bonus.operation:
                "flat_add":
                    resolved_stats[stat_name] += bonus.value
                "mul_add":
                    if resolved_stats[stat_name] == 0.0:
                        resolved_stats[stat_name] = 1.0
                    resolved_stats[stat_name] *= 1.0 + bonus.value
    stats_recalculated.emit()

func get_stat(stat_name: String, default_value: Variant = 0.0) -> Variant:
    return resolved_stats.get(stat_name, default_value)
