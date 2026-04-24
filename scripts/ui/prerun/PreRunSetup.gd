extends Control

@export_category("References")
@export var class_list_path: NodePath = NodePath("MarginContainer/PanelContainer/VBoxContainer/TabContainer/ClassTab/ClassList")
@export var class_description_path: NodePath = NodePath("MarginContainer/PanelContainer/VBoxContainer/TabContainer/ClassTab/ClassDescription")
@export var perk_list_path: NodePath = NodePath("MarginContainer/PanelContainer/VBoxContainer/TabContainer/PerksTab/ScrollContainer/PerkList")
@export var selected_perks_label_path: NodePath = NodePath("MarginContainer/PanelContainer/VBoxContainer/TabContainer/PerksTab/SelectedPerksLabel")
@export var talent_root_path: NodePath = NodePath("MarginContainer/PanelContainer/VBoxContainer/TabContainer/TalentsTab/TalentCanvas")

@onready var class_list: ItemList = get_node_or_null(class_list_path)
@onready var class_description: Label = get_node_or_null(class_description_path)
@onready var perk_list: VBoxContainer = get_node_or_null(perk_list_path)
@onready var selected_perks_label: Label = get_node_or_null(selected_perks_label_path)
@onready var talent_root: Control = get_node_or_null(talent_root_path)

func _ready() -> void:
    _build_class_tab()
    _build_perk_tab()
    _build_talent_tab()

func _build_class_tab() -> void:
    if class_list == null:
        return
    class_list.clear()
    var classes := ContentDB.get_all_class_defs()
    for index in range(classes.size()):
        var class_def: Dictionary = classes[index]
        class_list.add_item(class_def.get("display_name", class_def.get("id", "Class")))
        if StringName(class_def.get("id", "")) == RunState.selected_class_id:
            class_list.select(index)
            if class_description != null:
                class_description.text = class_def.get("description", "")

func _build_perk_tab() -> void:
    if perk_list == null:
        return
    for child in perk_list.get_children():
        child.queue_free()
    for perk_def in ContentDB.get_all_perks():
        var button := CheckBox.new()
        var perk_id := StringName(perk_def.get("id", ""))
        button.text = "%s — %s" % [perk_def.get("display_name", "Perk"), perk_def.get("description", "")]
        button.button_pressed = RunState.selected_perk_ids.has(perk_id)
        button.toggled.connect(_on_perk_toggled.bind(perk_id, button))
        perk_list.add_child(button)
    _refresh_selected_perks_label()

func _build_talent_tab() -> void:
    if talent_root == null:
        return
    for child in talent_root.get_children():
        child.queue_free()
    for talent in ContentDB.get_talent_stubs():
        var button := Button.new()
        button.text = "%s\n%s" % [talent.get("display_name", "Talent"), talent.get("description", "")]
        button.custom_minimum_size = Vector2(160, 72)
        button.position = talent.get("position", Vector2.ZERO)
        talent_root.add_child(button)

func _on_class_list_item_selected(index: int) -> void:
    var classes := ContentDB.get_all_class_defs()
    if index < 0 or index >= classes.size():
        return
    var class_def: Dictionary = classes[index]
    RunState.selected_class_id = StringName(class_def.get("id", "class_ink_duelist"))
    if class_description != null:
        class_description.text = class_def.get("description", "")

func _on_perk_toggled(enabled: bool, perk_id: StringName, button: CheckBox) -> void:
    if enabled:
        if RunState.selected_perk_ids.has(perk_id):
            return
        if not RunState.can_equip_more_perks():
            button.button_pressed = false
            return
    RunState.toggle_perk(perk_id)
    _refresh_selected_perks_label()

func _refresh_selected_perks_label() -> void:
    if selected_perks_label == null:
        return
    var names: Array[String] = []
    for perk_id in RunState.selected_perk_ids:
        names.append(ContentDB.get_perk_def(perk_id).get("display_name", String(perk_id)))
    selected_perks_label.text = "Selected Perks (%d/%d): %s" % [RunState.selected_perk_ids.size(), RunState.MAX_PERKS_EQUIPPED, ", ".join(names)]

func _on_back_button_pressed() -> void:
    Game.goto_main_menu()

func _on_begin_run_button_pressed() -> void:
    Game.start_run()
