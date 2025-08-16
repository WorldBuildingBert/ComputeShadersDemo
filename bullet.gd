##-------------##
#just a basic bullet scene for the demoshooter
##-------------##

extends Node3D

const speed:float = -9
signal Hit(pos)

func _on_timer_timeout() -> void:
	queue_free()


func _process(delta: float) -> void:
	global_position += global_transform.basis.z*delta*speed

func _on_area_3d_body_entered(body: Node3D) -> void:
	emit_signal("Hit", global_position)
	queue_free()
