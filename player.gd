extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 5.5
var enable_bhop = true
var mouse_speed = 2.0
var look_rot = Vector3.ZERO
var look_deg = 80
var camera_lean_rot = 0
var collision_height = 2.0
var total_speed = 0.0
var has_jumped = false
@onready var flashlight = get_node("CameraPivot/Camera3D/SpotLight3D") as SpotLight3D
@onready var camera = get_node("CameraPivot/Camera3D") as Camera3D
@onready var camera_pivot = get_node("CameraPivot") as Node3D
@onready var interact = get_node("Interact") as Area3D
@onready var collision = get_node("CollisionShape3D") as CollisionShape3D
var interact_list = []

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*2.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interact.connect("area_entered",area_entered)
	interact.connect("area_exited",area_exited)
	total_speed = SPEED

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var ms = mouse_speed/1000
		look_rot.x = camera.rotation.x - ms*event.relative.y
		look_rot.y = rotation.y - ms*event.relative.x
		camera.rotation.x = clamp(lerp_angle(camera.rotation.x, look_rot.x, 1.0), deg_to_rad(-look_deg), deg_to_rad(look_deg))
		rotation.y = look_rot.y

func _process(delta):
	if Input.is_action_just_pressed("flashlight"):
		if flashlight.visible:
			flashlight.hide()
		else:
			flashlight.show()
			
	if Input.is_action_just_pressed("interact"):
		for i in interact_list:
			i.toggle_door()
	
	var input_dir = Input.get_vector("lean_left", "lean_right","lean_left", "lean_right")
	
	var deg = 25
	camera_lean_rot = deg_to_rad(-deg)*input_dir.x
	camera_pivot.rotation.z = clamp(lerp_angle(camera_pivot.rotation.z, camera_lean_rot, 0.1*60*delta), deg_to_rad(-deg), deg_to_rad(deg))
	
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_size(DisplayServer.screen_get_size())
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(1280,720))

func _physics_process(delta):
	var input_dir = Input.get_vector("movement_left", "movement_right", "movement_forward", "movement_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	for col_idx in get_slide_collision_count():
		var col := get_slide_collision(col_idx)
		if col.get_collider() is RigidBody3D:
			col.get_collider().apply_central_impulse(-col.get_normal() * 0.3)
			col.get_collider().apply_impulse(-col.get_normal() * 0.01, col.get_position())
	
	if Input.is_action_pressed("movement_crouch"):
		collision_height = lerp(collision_height, 1.0, 0.2)
		if !has_jumped:
			total_speed = SPEED/2.0
	else:
		if $HeadCollision.get_overlapping_bodies().size() <= 0:
			collision_height = lerp(collision_height, 2.0, 0.2)

	
	collision.shape.height = collision_height
	
	if Input.is_action_just_pressed("movement_jump") and is_on_floor():
		if enable_bhop:
			total_speed += 1.0
		has_jumped = true
		velocity.y = JUMP_VELOCITY
		if direction:
			velocity.x = direction.x * total_speed
			velocity.z = direction.z * total_speed
	else:
		if is_on_floor():
			if has_jumped:
				has_jumped = false
			else:
				if direction:
					velocity.x = direction.x * total_speed
					velocity.z = direction.z * total_speed
				else:
					velocity.x = move_toward(velocity.x, 0, 0.5)
					velocity.z = move_toward(velocity.z, 0, 0.5)
				total_speed = lerpf(total_speed, SPEED, 0.5)
		else:
			if direction:
				velocity.x = direction.x * total_speed
				velocity.z = direction.z * total_speed
	
	move_and_slide()

func area_entered(area):
	if area.is_in_group("door"):
		interact_list.append(area.get_parent())

func area_exited(area):
	interact_list.erase(area.get_parent())
