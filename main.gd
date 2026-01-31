extends Node2D

@onready var transparent_window = $"TransparentWindow"
@onready var pet_polygon = $Polygon2D
@onready var animated_sprite = $AnimatedSprite2D

var dragging = false
var drag_offset = Vector2.ZERO

# Pet behavior variables
enum State { IDLE, WALKING, SLEEPING }
var current_state = State.IDLE
var walk_direction = 1  # 1 for right, -1 for left
var walk_speed = 0.0
var state_timer = 0.0
var next_state_duration = 0.0

# Screen bounds
var screen_size = Vector2.ZERO
var sprite_offset = Vector2.ZERO
var pet_bounds_margin = 100  # Distance from edge before turning around

func _ready():
	screen_size = get_viewport_rect().size
	# Store the sprite's offset from the parent node
	sprite_offset = animated_sprite.position
	# Start in the middle of the screen, accounting for sprite offset
	position = screen_size / 2 - sprite_offset
	_start_new_state()

func _process(delta):
	# Update hover state every frame for click-through
	var mouse_pos = get_viewport().get_mouse_position()
	var local_pos = pet_polygon.to_local(mouse_pos)
	var inside = pet_polygon.polygon and Geometry2D.is_point_in_polygon(local_pos, pet_polygon.polygon)
	
	# Toggle clickthrough depending on hover
	transparent_window.set_click_through(!inside and !dragging)
	
	# Don't process behavior while dragging
	if dragging:
		_clamp_to_screen()
		return
	
	# Update state timer
	state_timer += delta
	
	# Check if it's time to change state
	if state_timer >= next_state_duration:
		_start_new_state()
	
	# Process current state
	match current_state:
		State.WALKING:
			_process_walking(delta)
		State.IDLE:
			_process_idle()
		State.SLEEPING:
			_process_sleeping()

func _process_walking(delta):
	# Move the pet
	position.x += walk_direction * walk_speed * delta
	
	# Get the actual screen position of the sprite
	var sprite_screen_pos = position + sprite_offset
	
	# Check bounds and turn around if needed
	if sprite_screen_pos.x < pet_bounds_margin:
		position.x = pet_bounds_margin - sprite_offset.x
		walk_direction = 1
	elif sprite_screen_pos.x > screen_size.x - pet_bounds_margin:
		position.x = screen_size.x - pet_bounds_margin - sprite_offset.x
		walk_direction = -1
	
	# Flip sprite based on direction
	animated_sprite.flip_h = walk_direction < 0
	
	_clamp_to_screen()

func _process_idle():
	# Just playing idle animation, nothing else to do
	pass

func _process_sleeping():
	# Just playing sleeping animation, nothing else to do
	pass

func _start_new_state():
	state_timer = 0.0
	
	# Get the actual screen position of the sprite for boundary checks
	var sprite_screen_pos = position + sprite_offset
	
	# Randomly choose next state with weighted probabilities
	var rand = randf()
	
	if rand < 0.5:  # 50% chance to walk
		current_state = State.WALKING
		walk_speed = randf_range(80.0, 200.0)  # Random speed between 80-200 pixels/sec
		next_state_duration = randf_range(3.0, 8.0)  # Walk for 3-8 seconds
		
		# Randomly choose direction (or keep current if at edge)
		if sprite_screen_pos.x <= pet_bounds_margin:
			walk_direction = 1
		elif sprite_screen_pos.x >= screen_size.x - pet_bounds_margin:
			walk_direction = -1
		else:
			walk_direction = 1 if randf() > 0.5 else -1
		
		animated_sprite.play("Orchidea_Walking")
		animated_sprite.flip_h = walk_direction < 0
		
	elif rand < 0.85:  # 35% chance to idle
		current_state = State.IDLE
		next_state_duration = randf_range(2.0, 6.0)  # Idle for 2-6 seconds
		animated_sprite.play("Orchidea_Idle")
		
	else:  # 15% chance to sleep
		current_state = State.SLEEPING
		next_state_duration = randf_range(4.0, 10.0)  # Sleep for 4-10 seconds
		animated_sprite.play("Orchidea_Sleeping")

func _clamp_to_screen():
	# Account for sprite offset when clamping to screen
	var sprite_screen_pos = position + sprite_offset
	
	# Clamp the sprite's screen position
	sprite_screen_pos.x = clamp(sprite_screen_pos.x, pet_bounds_margin, screen_size.x - pet_bounds_margin)
	sprite_screen_pos.y = clamp(sprite_screen_pos.y, pet_bounds_margin, screen_size.y - pet_bounds_margin)
	
	# Convert back to node position
	position = sprite_screen_pos - sprite_offset


# INPUT HANDLING WITH STARTLE
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var local_pos = pet_polygon.to_local(event.position)
		if pet_polygon.polygon and Geometry2D.is_point_in_polygon(local_pos, pet_polygon.polygon):
			# If sleeping → play startled animation
			if animated_sprite.animation == "Orchidea_Sleeping":
				_startle()
			else:
				# Begin dragging if not sleeping
				dragging = true
				drag_offset = event.position - position
	elif event is InputEventMouseButton and not event.pressed:
		dragging = false
	elif event is InputEventMouseMotion and dragging:
		position = event.position - drag_offset
		_clamp_to_screen()


# STARTLE BEHAVIOR
func _startle():
	animated_sprite.play("Orchidea_Startled")
	await get_tree().create_timer(1.5).timeout
	animated_sprite.play("Orchidea_Idle")
	current_state = State.IDLE
	state_timer = 0.0
	next_state_duration = randf_range(2.0, 6.0)
