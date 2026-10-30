extends Node
func _ready() -> void:
	await get_tree().create_timer(1.5).timeout
	GameState.broom = true; GameState.marks = 20; GameState.order = "emberwing"
	GameState.check_honours()
	print("honours=", GameState.honours.keys())
	get_tree().quit()
