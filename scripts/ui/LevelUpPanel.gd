extends Control
class_name LevelUpPanel

signal choice_selected(modifier_id: StringName)

@export_category("References")
@export var button_list_path: NodePath = NodePath("PanelContainer/MarginContainer/VBoxContainer/ButtonList")

@onready var button_list: VBoxContainer = get_node_or_null(button_list_path)

func set_choices(modifier_ids: Array[StringName]) -> void:
    if button_list == null:
        return
    for child in button_list.get_children():
        child.queue_free()

    var shuffled := modifier_ids.duplicate()
    shuffled.shuffle()
    for modifier_id in shuffled.slice(0, min(3, shuffled.size())):
        var modifier_def := ContentDB.get_modifier_def(modifier_id)
        var button := Button.new()
        button.text = "%s\n%s" % [modifier_def.get("display_name", String(modifier_id)), modifier_def.get("description", "")]
        button.custom_minimum_size = Vector2(320.0, 72.0)
        button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        button.pressed.connect(_on_choice_pressed.bind(modifier_id))
        button_list.add_child(button)

func _on_choice_pressed(modifier_id: StringName) -> void:
    choice_selected.emit(modifier_id)
