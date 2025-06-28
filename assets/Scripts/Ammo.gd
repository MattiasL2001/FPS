extends Interactable

@export var ammo_amount: int = 30
@export var weapon_type: WeaponType.Type

func interact_with(player: Player) -> void:
	player.give_ammo(ammo_amount, weapon_type)
	queue_free()

func get_interact_text() -> String:
	return "Press E to pick up " + WeaponType.Type.keys()[weapon_type] + " ammo"
