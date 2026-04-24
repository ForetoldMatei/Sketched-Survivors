extends RefCounted
class_name RuntimeSkill

var skill_id: StringName
var display_name: String = ""
var tags: Array[StringName] = []
var values: Dictionary = {}

func setup_from_skill_def(skill_def: Dictionary) -> void:
    skill_id = StringName(skill_def.get("id", ""))
    display_name = String(skill_def.get("display_name", ""))
    tags.clear()
    for tag in skill_def.get("tags", []):
        tags.append(StringName(tag))
    values = skill_def.get("base_values", {}).duplicate(true)

func has_tag(tag_name: StringName) -> bool:
    return tags.has(tag_name)

func add_tag(tag_name: StringName) -> void:
    if not tags.has(tag_name):
        tags.append(tag_name)

func set_value(key: String, value: Variant) -> void:
    values[key] = value

func add_value(key: String, value: float) -> void:
    values[key] = float(values.get(key, 0.0)) + value

func multiply_value(key: String, factor_delta: float) -> void:
    values[key] = float(values.get(key, 0.0)) * (1.0 + factor_delta)

func get_value(key: String, default_value: Variant = null) -> Variant:
    return values.get(key, default_value)
