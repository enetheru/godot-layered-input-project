extends Node

##[codeblock lang=text]
##│ ___ _              ___         _           _
##│| _ \ |__ _ _  _   / __|___ _ _| |_ _ _ ___| |___
##│|  _/ / _` | || | | (__/ _ \ ' \  _| '_/ _ \ (_-<
##│|_| |_\__,_|\_, |  \___\___/_||_\__|_| \___/_/__/
##╰────────────|__/───────────────────────────────────
##[/codeblock]Mounts the gameplay responder and moves the cube from a camera behind it.
##
## Copy this for a player. The responder is not a scene-tree child. [InputManager] keeps it.
## The map names the actions. [code]_input[/code] handles the ones that are single events.
## Held movement is read each frame from the merged [InputMap], which is what [method Input.get_vector] sees.
## The nose on the cube points along local [code]-Z[/code]. The camera sits on local [code]+Z[/code], behind that nose.


const ACTION_LEFT:StringName = &"move_left"
const ACTION_RIGHT:StringName = &"move_right"
const ACTION_FORWARD:StringName = &"move_forward"
const ACTION_BACK:StringName = &"move_back"
const ACTION_JUMP:StringName = &"jump"
const ACTION_OPEN_MENU:StringName = &"open_menu"

const MOVE_SPEED:float = 8.0
const JUMP_SPEED:float = 6.5
const GRAVITY:float = 14.0
const FLOOR_Y:float = 0.5
const YARD:float = 32.0
const CAM_HEIGHT:float = 3.6
const CAM_DISTANCE:float = 7.0
const CAM_LOOK_Y:float = 0.9
const TURN_RATE:float = 10.0
const CAM_RATE:float = 8.0

const Responder = preload("uid://cjpmfrvsqx7jo")
const TreeViewScript = preload( "res://demo/tree_view.gd" )


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

## Emitted when the player asks for the menu. This script does not build that layer.
signal menu_requested

@onready var body:MeshInstance3D = $"../Body"
@onready var camera:Camera3D = $"../Camera3D"

var _record:Responder
var _trace:TreeViewScript
var _movement_paused:bool = false
var _vertical_speed:float = 0.0
var _start:Vector3
var _start_basis:Basis
var _body_mat:StandardMaterial3D
var _body_color:Color = Color( 0.2, 0.55, 0.85, 1 )
var _flash:float = 0.0
var _camera_held:bool = false


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _ready() -> void:
	_start = body.position
	_start_basis = body.basis
	_body_mat = body.get_surface_override_material( 0 ) as StandardMaterial3D
	if _body_mat != null:
		_body_color = _body_mat.albedo_color
	_mount()


func _process( delta:float ) -> void:
	_apply_motion( delta )
	_place_camera( delta )
	_cool_pulse( delta )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

#region Mount
#MARK: Mount
func                        __Mount__________________              ()->void:pass
# │ __  __              _
# │|  \/  |___ _  _ _ _| |_
# │| |\/| / _ \ || | ' \  _|
# │|_|  |_\___/\_,_|_||_\__|
# ╰──────────────────────────

## Build the record, point [code]_input[/code] at this object, and mount it.
## [InputManager] appends it under the link root. Later records sit in front of it on the walk.
func _mount() -> void:
	_record = Responder.new()
	_record.input_map = _build_map()
	_record._input = _on_input
	_record.set_meta( &"layer_name", &"play" )
	InputManager.add_responder( _record )


func set_trace( view:TreeViewScript ) -> void:
	_trace = view


## The menu calls this while its own responder is mounted.
## Sampling must stop here. Marking a key handled does not release a held action,
## so [method Input.get_vector] would keep moving the cube after the press.
func set_movement_paused( paused:bool ) -> void:
	_movement_paused = paused


## Return the cube to where it woke, facing the way it woke.
func reset_place() -> void:
	body.position = _start
	body.basis = _start_basis
	_vertical_speed = 0.0
	_camera_held = false


## A short colour pulse so a menu confirm is visible on the cube.
func pulse() -> void:
	_flash = 0.35


func _build_map() -> CustomInputMap:
	var map:CustomInputMap = CustomInputMap.new()
	map.resource_name = "play"
	_bind( map, ACTION_LEFT, [KEY_A, KEY_LEFT] )
	_bind( map, ACTION_RIGHT, [KEY_D, KEY_RIGHT] )
	_bind( map, ACTION_FORWARD, [KEY_W, KEY_UP] )
	_bind( map, ACTION_BACK, [KEY_S, KEY_DOWN] )
	_bind( map, ACTION_JUMP, [KEY_SPACE] )
	_bind( map, ACTION_OPEN_MENU, [KEY_ESCAPE] )
	return map


func _bind( map:CustomInputMap, action:StringName, keys:Array[Key] ) -> void:
	var events:Array[InputEvent] = []
	for key:Key in keys:
		events.append( _key( key ) )
	var _action:InputAction = map.add_action( action, CustomInputMap.DEFAULT_DEADZONE, events )


func _key( code:Key ) -> InputEventKey:
	var event:InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	return event


## Jump and the menu request are events, so they belong in the callback.
## Movement is not here. A held key is a state on the merged map, read from [method _process].
## Opening the menu only emits [signal menu_requested]. The menu script pushes its own record.
func _on_input( event:InputEvent ) -> void:
	var consumed:bool = false
	if _pressed( event, ACTION_JUMP ) and not _movement_paused:
		_jump()
		get_viewport().set_input_as_handled()
		consumed = true
	elif _pressed( event, ACTION_OPEN_MENU ):
		menu_requested.emit()
		get_viewport().set_input_as_handled()
		consumed = true

	if _trace != null and _record != null:
		_trace.note_dispatch( _record, event, consumed )


func _pressed( event:InputEvent, action:StringName ) -> bool:
	if not event.is_action_type():
		return false
	if not InputMap.has_action( action ):
		return false
	return event.is_action_pressed( action, false )


func _jump() -> void:
	if body.position.y > FLOOR_Y + 0.05:
		return
	_vertical_speed = JUMP_SPEED

#endregion Mount


#region Motion
#MARK: Motion
func                        __Motion_________________              ()->void:pass
# │ __  __     _   _
# │|  \/  |___| |_(_)___ _ _
# │| |\/| / _ \  _| / _ \ ' \
# │|_|  |_\___/\__|_\___/_||_|
# ╰────────────────────────────

func _apply_motion( delta:float ) -> void:
	# Wait until the merged map exists. get_vector warns on a missing action.
	if not _movement_paused and InputMap.has_action( ACTION_LEFT ):
		var wish:Vector2 = Input.get_vector(
				ACTION_LEFT,
				ACTION_RIGHT,
				ACTION_BACK,
				ACTION_FORWARD )
		# Ground axes of the cube. Once the camera is behind it, these match the view.
		var forward:Vector3 = -body.global_basis.z
		var right:Vector3 = body.global_basis.x
		forward.y = 0.0
		right.y = 0.0
		if forward.length_squared() > 0.0001 and right.length_squared() > 0.0001:
			forward = forward.normalized()
			right = right.normalized()
			var dir:Vector3 = right * wish.x + forward * wish.y
			if dir.length_squared() > 0.0001:
				var flat:Vector3 = Vector3( dir.x, 0.0, dir.z ).normalized()
				body.position += flat * MOVE_SPEED * delta
				# Face the move so the camera, sitting on +Z, stays behind the nose.
				var aim:Basis = Basis.looking_at( flat, Vector3.UP )
				var turn:float = 1.0 - exp( -TURN_RATE * delta )
				body.basis = body.basis.slerp( aim, turn )

		body.position.x = clampf( body.position.x, -YARD, YARD )
		body.position.z = clampf( body.position.z, -YARD, YARD )

	_vertical_speed -= GRAVITY * delta
	body.position.y += _vertical_speed * delta
	if body.position.y <= FLOOR_Y:
		body.position.y = FLOOR_Y
		_vertical_speed = 0.0


## Sit behind the cube and look at it. [code]+Z[/code] is the back of a node that faces [code]-Z[/code].
func _place_camera( delta:float ) -> void:
	var back:Vector3 = body.global_basis.z
	var goal:Vector3 = body.global_position + Vector3.UP * CAM_HEIGHT + back * CAM_DISTANCE
	if not _camera_held:
		camera.global_position = goal
		_camera_held = true
	else:
		var follow:float = 1.0 - exp( -CAM_RATE * delta )
		camera.global_position = camera.global_position.lerp( goal, follow )
	camera.look_at( body.global_position + Vector3.UP * CAM_LOOK_Y, Vector3.UP )


func _cool_pulse( delta:float ) -> void:
	if _body_mat == null or _flash <= 0.0:
		return
	_flash = maxf( _flash - delta, 0.0 )
	var blend:float = _flash / 0.35
	_body_mat.albedo_color = _body_color.lerp( Color( 0.95, 0.75, 0.28 ), blend )

#endregion Motion
