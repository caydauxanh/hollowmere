extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	var hud = get_tree().current_scene.get_node("HUD"); hud._close_dialogue()
	GameState.coins = 77; GameState.marks = 9
	GameState.save_game()
	print("exists=", FileAccess.file_exists(GameState.SAVE_PATH), " path=", ProjectSettings.globalize_path(GameState.SAVE_PATH), " len=", FileAccess.get_file_as_string(GameState.SAVE_PATH).length(), " err=", FileAccess.get_open_error())
	hud._toggle_save_panel()
	var code: String = hud._save_edit.text
	print("code len=", code.length())
	GameState.coins = 0; GameState.marks = 0
	hud._save_edit.text = code
	hud._save_action("load")
	print("after load coins=", GameState.coins, " marks=", GameState.marks)
	get_tree().quit()
