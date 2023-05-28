extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 5.5
var mouse_speed = 2.0
var look_rot = Vector3.ZERO
var look_deg = 80

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")*2.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if event is InputEventMouseMotion:
		var ms = mouse_speed/1000
		look_rot.x = $Camera3D.rotation.x - ms*event.relative.y
		look_rot.y = rotation.y - ms*event.relative.x
		$Camera3D.rotation.x = clamp(lerp_angle($Camera3D.rotation.x, look_rot.x, 1.0), deg_to_rad(-look_deg), deg_to_rad(look_deg))
		rotation.y = look_rot.y

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("movement_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("movement_left", "movement_right", "movement_forward", "movement_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, 0.8)
			velocity.z = move_toward(velocity.z, 0, 0.8)

	move_and_slide()
