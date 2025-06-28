extends RangedWeapon

func _init():
	weapon_name = "Sniper1"
	is_scoped = true
	can_aim = true
	aim_fov = 20
	recoil_strength = .05
	recoil_recovery_speed = 0.1
	weapon_type = WeaponType.Type.PRIMARY
	fire_range = 75
	fire_rate = 1.5
	damage = 125
	clip_size = 7
	reload_rate = 3
	ammo_total = 14
	camera_shake = 0.05
