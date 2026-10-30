@tool
extends EditorScenePostImport
## Keeps only the animations the game uses (the KayKit characters ship ~70 each).

const KEEP := ["Idle", "Walking_A", "Running_A", "Jump_Idle", "Spellcast_Shoot", "Spellcast_Raise", "PickUp", "Interact", "Cheer"]

func _post_import(scene: Node) -> Object:
	var ap: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
	if ap:
		for lib_name in ap.get_animation_library_list():
			var lib := ap.get_animation_library(lib_name)
			for a in lib.get_animation_list():
				if not KEEP.has(String(a)):
					lib.remove_animation(a)
	return scene
