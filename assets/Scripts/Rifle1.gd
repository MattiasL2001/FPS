extends RangedWeapon

func _init():
	weapon_name = "Rifle1"
	weapon_type = WeaponType.Type.PRIMARY
	can_aim = true
	fire_range = 80
	fire_rate = 0.1
	aim_fov = 50
	ads_position = Vector3(0.011, -0.225, -0.5)
	ads_rotation = Vector3(0, -90, -0.5)
	damage = 21
	clip_size = 30
	reload_rate = 2
	ammo_total = 90
	camera_shake = 0.05
