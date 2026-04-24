extends Node

const CLASS_DEFS := {
    "class_ink_duelist": {
        "id": "class_ink_duelist",
        "display_name": "Ink Duelist",
        "description": "A nimble sketch fighter who fires Ink Bolts and carves through enemies with a dash slash.",
        "base_stats": {
            "max_health": 100.0,
            "move_speed": 230.0,
            "projectile_damage_mult": 1.0,
            "projectile_speed_mult": 1.0,
            "area_mult": 1.0,
            "cooldown_mult": 1.0,
            "pickup_radius": 52.0,
            "dash_distance_mult": 1.0,
            "projectile_bounce": 0.0,
            "vampire_pool_chance": 0.0,
            "healing_power_mult": 1.0,
            "contact_damage_interval": 0.5
        },
        "starting_auto_attack": "skill_ink_bolt",
        "starting_active_skill": "skill_dash_slash"
    },
    "class_ink_knight": {
        "id": "class_ink_knight",
        "display_name": "Ink Knight",
        "description": "A sturdy frontliner who swings in a wide arc and restores health with their active skill.",
        "base_stats": {
            "max_health": 135.0,
            "move_speed": 200.0,
            "projectile_damage_mult": 1.0,
            "projectile_speed_mult": 1.0,
            "area_mult": 1.0,
            "cooldown_mult": 1.0,
            "pickup_radius": 52.0,
            "dash_distance_mult": 1.0,
            "projectile_bounce": 0.0,
            "vampire_pool_chance": 0.0,
            "healing_power_mult": 1.0,
            "contact_damage_interval": 0.5,
            "melee_damage_mult": 1.0
        },
        "starting_auto_attack": "skill_knight_cleave",
        "starting_active_skill": "skill_sanguine_guard"
    }
}

const SKILLS := {
    "skill_ink_bolt": {
        "id": "skill_ink_bolt",
        "display_name": "Ink Bolt",
        "kind": "auto_attack",
        "tags": ["projectile", "single_target", "physical", "projectile_scaled"],
        "base_values": {
            "damage": 14.0,
            "speed": 460.0,
            "lifetime": 1.25,
            "radius": 7.0,
            "cooldown": 0.35,
            "pierce": 0,
            "bounce": 0,
            "splash_radius": 0.0
        }
    },
    "skill_dash_slash": {
        "id": "skill_dash_slash",
        "display_name": "Dash Slash",
        "kind": "active",
        "tags": ["movement", "aoe", "physical", "aoe_scaled"],
        "base_values": {
            "cooldown": 3.5,
            "dash_distance": 160.0,
            "dash_duration": 0.16,
            "damage": 26.0,
            "radius": 44.0,
            "damage_multiplier": 1.0,
            "invulnerability_duration": 0.16,
            "hit_interval": 0.04
        }
    },
    "skill_knight_cleave": {
        "id": "skill_knight_cleave",
        "display_name": "Knight Cleave",
        "kind": "auto_attack",
        "tags": ["melee", "aoe", "physical", "aoe_scaled"],
        "base_values": {
            "damage": 22.0,
            "cooldown": 0.72,
            "radius": 72.0,
            "arc_degrees": 180.0
        }
    },
    "skill_sanguine_guard": {
        "id": "skill_sanguine_guard",
        "display_name": "Sanguine Guard",
        "kind": "active",
        "tags": ["heal", "utility"],
        "base_values": {
            "cooldown": 6.0,
            "heal_percent": 0.10,
            "flat_heal": 0.0
        }
    }
}

const MODIFIERS := {
    "mod_projectile_damage_up": {
        "id": "mod_projectile_damage_up",
        "display_name": "Darker Lines",
        "description": "+20% projectile damage.",
        "kind": "stat",
        "stat": "projectile_damage_mult",
        "operation": "mul_add",
        "value": 0.20,
        "class_restrictions": ["class_ink_duelist"]
    },
    "mod_add_splash": {
        "id": "mod_add_splash",
        "display_name": "Ink Burst",
        "description": "Ink Bolt gains Splash and small AOE.",
        "kind": "skill_tag_value",
        "skill_id": "skill_ink_bolt",
        "add_tags": ["splash", "aoe", "aoe_scaled"],
        "set_values": {"splash_radius": 32.0},
        "class_restrictions": ["class_ink_duelist"]
    },
    "mod_area_up": {
        "id": "mod_area_up",
        "display_name": "Broader Strokes",
        "description": "+25% area size.",
        "kind": "stat",
        "stat": "area_mult",
        "operation": "mul_add",
        "value": 0.25
    },
    "mod_long_strokes": {
        "id": "mod_long_strokes",
        "display_name": "Long Strokes",
        "description": "Your dash distance is increased by 10%.",
        "kind": "stat",
        "stat": "dash_distance_mult",
        "operation": "mul_add",
        "value": 0.10,
        "class_restrictions": ["class_ink_duelist"]
    },
    "mod_bouncy": {
        "id": "mod_bouncy",
        "display_name": "Bouncy",
        "description": "Your projectiles chain to +1 additional enemy.",
        "kind": "stat",
        "stat": "projectile_bounce",
        "operation": "flat_add",
        "value": 1.0,
        "class_restrictions": ["class_ink_duelist"]
    },
    "mod_vampire": {
        "id": "mod_vampire",
        "display_name": "Vampire",
        "description": "Kills have a chance to spawn a healing blood pool.",
        "kind": "stat",
        "stat": "vampire_pool_chance",
        "operation": "flat_add",
        "value": 0.20
    },
    "mod_dash_damage_up": {
        "id": "mod_dash_damage_up",
        "display_name": "Ink Momentum",
        "description": "Dash Slash deals +25% damage.",
        "kind": "skill_value_add",
        "skill_id": "skill_dash_slash",
        "value_adds": {"damage_multiplier": 0.25},
        "class_restrictions": ["class_ink_duelist"]
    },
    "mod_knight_cleave_damage": {
        "id": "mod_knight_cleave_damage",
        "display_name": "Heavy Cleave",
        "description": "+25% Knight Cleave damage.",
        "kind": "skill_value_mul_add",
        "skill_id": "skill_knight_cleave",
        "value_mul_adds": {"damage": 0.25},
        "class_restrictions": ["class_ink_knight"]
    },
    "mod_knight_cleave_area": {
        "id": "mod_knight_cleave_area",
        "display_name": "Broad Guard",
        "description": "+20% Knight Cleave radius.",
        "kind": "skill_value_mul_add",
        "skill_id": "skill_knight_cleave",
        "value_mul_adds": {"radius": 0.20},
        "class_restrictions": ["class_ink_knight"]
    },
    "mod_knight_heal_up": {
        "id": "mod_knight_heal_up",
        "display_name": "Restorative Ink",
        "description": "Sanguine Guard restores +5% max HP.",
        "kind": "skill_value_add",
        "skill_id": "skill_sanguine_guard",
        "value_adds": {"heal_percent": 0.05},
        "class_restrictions": ["class_ink_knight"]
    },
    "mod_knight_guard_cooldown": {
        "id": "mod_knight_guard_cooldown",
        "display_name": "Steady Heart",
        "description": "Sanguine Guard cooldown is reduced by 15%.",
        "kind": "skill_value_mul_add",
        "skill_id": "skill_sanguine_guard",
        "value_mul_adds": {"cooldown": -0.15},
        "class_restrictions": ["class_ink_knight"]
    }
}

const PERKS := {
    "perk_glass_ink": {
        "id": "perk_glass_ink",
        "display_name": "Glass Ink",
        "description": "+25% projectile damage, -20 max health.",
        "stat_mods": {
            "projectile_damage_mult": {"operation": "mul_add", "value": 0.25},
            "max_health": {"operation": "flat_add", "value": -20.0}
        }
    },
    "perk_swift_hand": {
        "id": "perk_swift_hand",
        "display_name": "Swift Hand",
        "description": "+10% movement speed.",
        "stat_mods": {
            "move_speed": {"operation": "mul_add", "value": 0.10}
        }
    },
    "perk_wide_ink": {
        "id": "perk_wide_ink",
        "display_name": "Wide Ink",
        "description": "+15% area size.",
        "stat_mods": {
            "area_mult": {"operation": "mul_add", "value": 0.15}
        }
    }
}

const TALENT_STUBS := [
    {
        "id": "talent_ink_body",
        "display_name": "Ink Body",
        "description": "+5 Max HP (placeholder)",
        "position": Vector2(180, 120)
    },
    {
        "id": "talent_fast_lines",
        "display_name": "Fast Lines",
        "description": "+4% Attack Speed (placeholder)",
        "position": Vector2(360, 80)
    },
    {
        "id": "talent_heavy_strokes",
        "display_name": "Heavy Strokes",
        "description": "+6% Damage (placeholder)",
        "position": Vector2(360, 200)
    }
]

func get_class_def(class_id: StringName) -> Dictionary:
    return CLASS_DEFS.get(String(class_id), {}).duplicate(true)

func get_all_class_defs() -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for value in CLASS_DEFS.values():
        results.append(value.duplicate(true))
    return results

func get_skill_def(skill_id: StringName) -> Dictionary:
    return SKILLS.get(String(skill_id), {}).duplicate(true)

func get_modifier_def(modifier_id: StringName) -> Dictionary:
    return MODIFIERS.get(String(modifier_id), {}).duplicate(true)

func get_perk_def(perk_id: StringName) -> Dictionary:
    return PERKS.get(String(perk_id), {}).duplicate(true)

func get_all_perks() -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for value in PERKS.values():
        results.append(value.duplicate(true))
    return results

func get_levelup_modifier_choices(class_id: StringName = &"") -> Array[StringName]:
    var results: Array[StringName] = []
    for modifier_id in MODIFIERS.keys():
        var modifier_def: Dictionary = MODIFIERS[modifier_id]
        var restrictions: Array = modifier_def.get("class_restrictions", [])
        if restrictions.is_empty() or restrictions.has(String(class_id)):
            results.append(StringName(modifier_id))
    return results

func get_talent_stubs() -> Array[Dictionary]:
    var results: Array[Dictionary] = []
    for entry in TALENT_STUBS:
        results.append(entry.duplicate(true))
    return results
