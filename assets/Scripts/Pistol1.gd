extends RangedWeapon

func _init():
	weapon_name = "Pistol1"
	weapon_type = WeaponType.Type.SECONDARY
	fire_range = 35
	fire_rate = 0.3
	aim_fov = 50
	can_aim = true
	ads_position = Vector3(0, -0.125, -0.4)
	damage = 18
	clip_size = 12
	reload_rate = 1
	ammo_total = 24
	camera_shake = 0.02
