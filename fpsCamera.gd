##--------------##
#the camera script nescescary for the shooter demo
#this is just a basic controller and can be ignored
##--------------##

extends Camera3D


const speed:float = 2
const turningspeed:float = 0.003

func _ready() -> void:
	Input.mouse_mode =  Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		#we have captured the mouse so we need to use the relative motion
		var movement :Vector2= event.get_relative()
		rotate_y(-movement.x*turningspeed)
		rotate(global_transform.basis.x, -movement.y*turningspeed)

func shoot():
	var bullet = load("res://bullet.tscn").instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = global_position
	bullet.global_transform = global_transform
	bullet.Hit.connect(get_parent().hit)

func _process(delta: float) -> void:
	#simple controler that moves to all 4 sides, but only in the x and z direction
	var lr := Input.get_axis("ui_left", "ui_right")
	var fb := Input.get_axis("ui_up", "ui_down")
	
	global_position += (global_transform.basis.z*fb + global_transform.basis.x*lr)*Vector3(1,0,1)*delta*speed


	#free the mouse when needed
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("ui_text_backspace"):
		Input.mouse_mode =  Input.MOUSE_MODE_VISIBLE
	
	if Input.is_action_just_pressed("ui_accept"):
		shoot()
