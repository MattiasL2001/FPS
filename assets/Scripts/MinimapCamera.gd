extends Camera3D

func _on_Player_update_transform(position : Vector3, rotation):
	set_position(Vector3(position.x, position.y + 100, position.z))
	set_rotation(Vector3(self.get_rotation().x, rotation, self.get_rotation().z))
