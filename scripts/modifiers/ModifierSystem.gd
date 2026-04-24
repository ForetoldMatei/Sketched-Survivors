extends RefCounted
class_name ModifierSystem

static func apply_modifier_to_player(player: Node, modifier_def: Dictionary) -> void:
    var kind: String = modifier_def.get("kind", "")
    match kind:
        "stat":
            player.stats_component.apply_stat_modifier(
                modifier_def.get("stat", ""),
                modifier_def.get("operation", "flat_add"),
                float(modifier_def.get("value", 0.0))
            )
        "skill_tag_value":
            var skill_id := StringName(modifier_def.get("skill_id", ""))
            var skill: RuntimeSkill = player.get_runtime_skill(skill_id)
            if skill == null:
                return
            for tag in modifier_def.get("add_tags", []):
                skill.add_tag(StringName(tag))
            var set_values: Dictionary = modifier_def.get("set_values", {})
            for key in set_values.keys():
                skill.set_value(String(key), set_values[key])
        "skill_value_add":
            var add_skill_id := StringName(modifier_def.get("skill_id", ""))
            var add_skill: RuntimeSkill = player.get_runtime_skill(add_skill_id)
            if add_skill == null:
                return
            var value_adds: Dictionary = modifier_def.get("value_adds", {})
            for key in value_adds.keys():
                add_skill.add_value(String(key), float(value_adds[key]))
        "skill_value_mul_add":
            var mul_skill_id := StringName(modifier_def.get("skill_id", ""))
            var mul_skill: RuntimeSkill = player.get_runtime_skill(mul_skill_id)
            if mul_skill == null:
                return
            var value_mul_adds: Dictionary = modifier_def.get("value_mul_adds", {})
            for key in value_mul_adds.keys():
                mul_skill.multiply_value(String(key), float(value_mul_adds[key]))

static func apply_perk_to_player(player: Node, perk_def: Dictionary) -> void:
    var stat_mods: Dictionary = perk_def.get("stat_mods", {})
    for stat_name in stat_mods.keys():
        var payload: Dictionary = stat_mods[stat_name]
        player.stats_component.apply_stat_modifier(
            String(stat_name),
            payload.get("operation", "flat_add"),
            float(payload.get("value", 0.0))
        )
