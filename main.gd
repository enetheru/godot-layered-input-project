extends Node3D

##[codeblock lang=text]
##│ __  __      _
##│|  \/  |__ _(_)_ _
##│| |\/| / _` | | ' \
##│|_|  |_\__,_|_|_||_|
##╰──────────────────────
##[/codeblock]Play, hint, and menu layers on one scene.
##
## Hint is a child of play, so it sees [code]_input[/code] first. H makes hint consume Space. Escape pushes menu in front of that branch and replaces jump.


const ACTION_LEFT:StringName = &"move_left"
const ACTION_RIGHT:StringName = &"move_right"
const ACTION_FORWARD:StringName = &"move_forward"
const ACTION_BACK:StringName = &"move_back"
const ACTION_JUMP:StringName = &"jump"
const ACTION_OPEN_MENU:StringName = &"open_menu"
const ACTION_CLOSE_MENU:StringName = &"close_menu"
const ACTION_CONFIRM:StringName = &"confirm"

const MOVE_SPEED:float = 4.0
const JUMP_SPEED:float = 5.0
const GRAVITY:float = 12.0
const FLOOR_Y:float = 0.5
const MOVE_LIMIT:float = 5.0

const ResponderScript = preload( "res://addons/enetheru.layered-input/systems/responder.gd" )
const TreeViewScript = preload( "res://demo/tree_view.gd" )


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

@onready var body:MeshInstance3D = $Body
@onready var camera:Camera3D = $Camera3D
@onready var _tree_view:TreeViewScript = $Hud/TreeScroll/TreeView

var _play:RefCounted
var _hint:RefCounted
var _menu:RefCounted
var _is_menu_open:bool = false
var _hint_holds:bool = false
var _vertical_speed:float = 0.0
var _body_mat:StandardMaterial3D
var _body_color:Color = Color( 0.2, 0.55, 0.85, 1 )
var _flash:float = 0.0


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

## Point the camera past the tree panel and mount play, with hint in front of it.
func _ready() -> void:
	camera.position = Vector3( -2.4, 4.6, 7.2 )
	camera.look_at( Vector3( 0.2, 0.45, 0.0 ) )
	_body_mat = body.get_surface_override_material( 0 ) as StandardMaterial3D
	if _body_mat != null:
		_body_color = _body_mat.albedo_color

	_play = _make_responder(
			&"play",
			_build_play_map(),
			Callable( self, &"_on_play_input" ) )
	_hint = _make_responder(
			&"hint",
			null,
			Callable( self, &"_on_hint_input" ) )
	# Child of play, so hint is in front of play on the walk.
	_play.call( &"add_responder", _hint )
	_menu = _make_responder(
			&"menu",
			_build_menu_map(),
			Callable( self, &"_on_menu_input" ) )
	InputManager.add_responder( _play )


## Slide, hop, and let a confirm flash fade.
func _process( delta:float ) -> void:
	_apply_motion( delta )
	_cool_flash( delta )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func _on_hint_input( event:InputEvent ) -> void:
	var consumed:bool = false
	if _key_pressed( event, KEY_H ):
		_hint_holds = not _hint_holds
		_hint.set_meta( &"holds", _hint_holds )
		get_viewport().set_input_as_handled()
		consumed = true
	elif _hint_holds and _pressed( event, ACTION_JUMP ):
		get_viewport().set_input_as_handled()
		consumed = true
	_note_dispatch( _hint, event, consumed )


func _on_play_input( event:InputEvent ) -> void:
	var consumed:bool = false
	if _pressed( event, ACTION_JUMP ):
		_jump()
		get_viewport().set_input_as_handled()
		consumed = true
	elif _pressed( event, ACTION_OPEN_MENU ):
		_open_menu()
		get_viewport().set_input_as_handled()
		consumed = true
	_note_dispatch( _play, event, consumed )


func _on_menu_input( event:InputEvent ) -> void:
	var consumed:bool = false
	if _pressed( event, ACTION_CLOSE_MENU ):
		_close_menu()
		get_viewport().set_input_as_handled()
		consumed = true
	elif _pressed( event, ACTION_CONFIRM ):
		_confirm()
		get_viewport().set_input_as_handled()
		consumed = true
	elif event.is_action_type():
		get_viewport().set_input_as_handled()
		consumed = true
	_note_dispatch( _menu, event, consumed )


func _open_menu() -> void:
	if _is_menu_open:
		return
	InputManager.add_responder( _menu )
	_is_menu_open = true


func _close_menu() -> void:
	if not _is_menu_open:
		return
	InputManager.remove_responder( _menu )
	_is_menu_open = false


func _confirm() -> void:
	_flash = 0.35


func _jump() -> void:
	if body.position.y > FLOOR_Y + 0.05:
		return
	_vertical_speed = JUMP_SPEED


func _apply_motion( delta:float ) -> void:
	if not _is_menu_open and InputMap.has_action( ACTION_LEFT ):
		var move:Vector2 = Input.get_vector(
				ACTION_LEFT,
				ACTION_RIGHT,
				ACTION_BACK,
				ACTION_FORWARD )
		body.position.x += move.x * MOVE_SPEED * delta
		body.position.z -= move.y * MOVE_SPEED * delta
		body.position.x = clampf( body.position.x, -MOVE_LIMIT, MOVE_LIMIT )
		body.position.z = clampf( body.position.z, -MOVE_LIMIT, MOVE_LIMIT )

	_vertical_speed -= GRAVITY * delta
	body.position.y += _vertical_speed * delta
	if body.position.y <= FLOOR_Y:
		body.position.y = FLOOR_Y
		_vertical_speed = 0.0


func _make_responder(
			_responder_name:StringName,
			map:CustomInputMap,
			handler:Callable ) -> RefCounted:
	var record:RefCounted = ResponderScript.new()
	if map != null:
		record.set( &"input_map", map )
	record.set( &"_input", handler )
	record.set_meta( &"layer_name", _responder_name )
	return record


func _build_play_map() -> CustomInputMap:
	var map:CustomInputMap = CustomInputMap.new()
	map.resource_name = "play"
	_bind( map, ACTION_LEFT, [KEY_A, KEY_LEFT] )
	_bind( map, ACTION_RIGHT, [KEY_D, KEY_RIGHT] )
	_bind( map, ACTION_FORWARD, [KEY_W, KEY_UP] )
	_bind( map, ACTION_BACK, [KEY_S, KEY_DOWN] )
	_bind( map, ACTION_JUMP, [KEY_SPACE] )
	_bind( map, ACTION_OPEN_MENU, [KEY_ESCAPE] )
	return map


func _build_menu_map() -> CustomInputMap:
	var map:CustomInputMap = CustomInputMap.new()
	map.resource_name = "menu"
	_bind( map, ACTION_CLOSE_MENU, [KEY_ESCAPE] )
	_bind( map, ACTION_CONFIRM, [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] )
	# Empty jump is written while menu is in front, so play's Space does not replace it.
	var _empty_jump:InputAction = map.add_action( ACTION_JUMP )
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


func _pressed( event:InputEvent, action:StringName ) -> bool:
	if not event.is_action_type():
		return false
	if not InputMap.has_action( action ):
		return false
	return event.is_action_pressed( action, false )


func _note_dispatch( record:RefCounted, event:InputEvent, consumed:bool ) -> void:
	if _tree_view == null:
		return
	_tree_view.note_dispatch( record, event, consumed )


func _key_pressed( event:InputEvent, code:Key ) -> bool:
	if event is not InputEventKey:
		return false
	var key:InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return false
	var got:Key = key.physical_keycode
	if got == KEY_NONE:
		got = key.keycode
	return got == code


func _cool_flash( delta:float ) -> void:
	if _body_mat == null or _flash <= 0.0:
		return
	_flash = maxf( _flash - delta, 0.0 )
	var blend:float = _flash / 0.35
	_body_mat.albedo_color = _body_color.lerp( Color( 0.95, 0.75, 0.28 ), blend )
