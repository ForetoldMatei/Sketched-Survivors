extends Node

const MAIN_MENU_SCENE := "res://scenes/ui/menus/MainMenu.tscn"
const PRE_RUN_SCENE := "res://scenes/ui/prerun/PreRunSetup.tscn"
const RUN_SCENE := "res://scenes/run/RunRoot.tscn"

func goto_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func goto_pre_run() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(PRE_RUN_SCENE)

func start_run() -> void:
	get_tree().paused = false
	EventBus.run_started.emit()
	get_tree().change_scene_to_file(RUN_SCENE)

func restart_run() -> void:
	start_run()
