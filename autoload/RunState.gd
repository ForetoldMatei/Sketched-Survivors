extends Node

const XP_CURVE_BASE: int = 5
const XP_CURVE_STEP: int = 4
const MAX_PERKS_EQUIPPED: int = 3

var selected_class_id: StringName = &"class_ink_duelist"
var selected_perk_ids: Array[StringName] = [StringName("perk_glass_ink")]
var active_talent_stub_ids: Array[StringName] = []

var current_level: int = 1
var current_xp: int = 0
var current_xp_to_next: int = XP_CURVE_BASE
var total_kills: int = 0
var is_levelup_pending: bool = false
var selected_modifier_ids: Array[StringName] = []

func reset_for_new_run() -> void:
    current_level = 1
    current_xp = 0
    current_xp_to_next = XP_CURVE_BASE
    total_kills = 0
    is_levelup_pending = false
    selected_modifier_ids.clear()

func add_xp(amount: int) -> void:
    if amount <= 0:
        return
    current_xp += amount
    EventBus.xp_collected.emit(amount)

    while current_xp >= current_xp_to_next:
        current_xp -= current_xp_to_next
        current_level += 1
        current_xp_to_next = XP_CURVE_BASE + (current_level - 1) * XP_CURVE_STEP
        is_levelup_pending = true
        EventBus.player_level_up.emit(current_level)

func record_kill() -> void:
    total_kills += 1

func toggle_perk(perk_id: StringName) -> void:
    if selected_perk_ids.has(perk_id):
        selected_perk_ids.erase(perk_id)
        return
    if selected_perk_ids.size() >= MAX_PERKS_EQUIPPED:
        return
    selected_perk_ids.append(perk_id)

func can_equip_more_perks() -> bool:
    return selected_perk_ids.size() < MAX_PERKS_EQUIPPED
