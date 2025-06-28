extends Node
class_name Interactable


func interact() -> void:
	print("standard interact implementation")
	#pass  # Kan skrivas över av barnklasser

func interact_with(player: Player) -> void:
	print("standard interact_with implementation")
	interact()  # Default: bara kalla på interact()

func get_interact_text() -> String:
	return "press E to interact"
