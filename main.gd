extends Node3D

##[codeblock lang=text]
##│ __  __      _
##│|  \/  |__ _(_)_ _
##│| |\/| / _` | | ' \
##│|_|  |_\__,_|_|_||_|
##╰──────────────────────
##[/codeblock]Play and menu layers on one scene.
##
## Escape pushes a menu responder. That layer replaces jump and takes Space. WASD moves the box while the menu is closed.


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


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

@onready var body:MeshInstance3D = $Body
@onready var camera:Camera3D = $Camera3D
@onready var status:Label = $Hud/Status

const ResponderScript = preload( "res://addons/enetheru.layered-input/systems/responder.gd" )

var _play:RefCounted
var _menu:RefCounted
var _is_menu_open:bool = false
var _vertical_speed:float = 0.0
var _note:String = "ready"


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

## Point the camera at the box and mount the play layer.
func _ready() -> void:
	camera.look_at( Vector3.ZERO )

	_play = _make_responder(
			&"play",
			_build_play_map(),
			Callable( self, &"_on_play_input" ) )
	_menu = _make_responder(
			&"menu",
			_build_menu_map(),
			Callable( self, &"_on_menu_input" ) )
	InputManager.add_responder( _play )


## Slide, hop, and refresh the binding readout.
func _process( delta:float ) -> void:
	_apply_motion( delta )
	_refresh_status()


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func _on_play_input( event:InputEvent ) -> void:
	if _pressed( event, ACTION_JUMP ):
		_jump()
		get_viewport().set_input_as_handled()
		return
	if _pressed( event, ACTION_OPEN_MENU ):
		_open_menu()
		get_viewport().set_input_as_handled()


func _on_menu_input( event:InputEvent ) -> void:
	if _pressed( event, ACTION_CLOSE_MENU ):
		_close_menu()
		get_viewport().set_input_as_handled()
		return
	if _pressed( event, ACTION_CONFIRM ):
		_confirm()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_type():
		get_viewport().set_input_as_handled()


func _open_menu() -> void:
	if _is_menu_open:
		return
	InputManager.add_responder( _menu )
	_is_menu_open = true
	_note = "open menu"


func _close_menu() -> void:
	if not _is_menu_open:
		return
	InputManager.remove_responder( _menu )
	_is_menu_open = false
	_note = "close menu"


func _confirm() -> void:
	_note = "confirm"


func _jump() -> void:
	if body.position.y > FLOOR_Y + 0.05:
		return
	_vertical_speed = JUMP_SPEED
	_note = "jump"


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
	# Same name as play, no events: later layer wins and Space stops being jump.
	map.add_action( ACTION_JUMP )
	return map


func _bind( map:CustomInputMap, action:StringName, keys:Array[Key] ) -> void:
	var events:Array[InputEvent] = []
	for key:Key in keys:
		events.append( _key( key ) )
	map.add_action( action, CustomInputMap.DEFAULT_DEADZONE, events )


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


func _refresh_status() -> void:
	var lines:PackedStringArray = PackedStringArray()
	lines.append( "Layers: %s" % _layer_names() )
	lines.append( "Menu: %s" % ( "open" if _is_menu_open else "closed" ) )
	lines.append( "WASD moves. Space jumps. Escape opens the menu." )
	lines.append( "In the menu, Space confirms and Escape closes it." )
	lines.append( _binding_line( ACTION_JUMP ) )
	lines.append( _binding_line( ACTION_CONFIRM ) )
	lines.append( _binding_line( ACTION_OPEN_MENU ) )
	lines.append( _binding_line( ACTION_CLOSE_MENU ) )
	lines.append( "Last: %s" % _note )
	status.text = "\n".join( lines )


func _binding_line( action:StringName ) -> String:
	if not InputMap.has_action( action ):
		return "%s: (not in map)" % action
	var events:Array[InputEvent] = InputMap.action_get_events( action )
	if events.is_empty():
		return "%s: (none)" % action
	var labels:PackedStringArray = PackedStringArray()
	for event:InputEvent in events:
		labels.append( _event_label( event ) )
	return "%s: %s" % [action, ", ".join( labels )]


func _event_label( event:InputEvent ) -> String:
	if event is InputEventKey:
		var key:InputEventKey = event
		var code:Key = key.physical_keycode
		if code == KEY_NONE:
			code = key.keycode
		return OS.get_keycode_string( code )
	return event.as_text()


func _layer_names() -> String:
	var link:Object = InputManager.get( &"tree" )
	if link == null:
		return "(no root)"
	var root:Object = link.get( &"root" )
	if root == null:
		return "(no root)"
	var names:Array[String] = []
	_collect_names( root, names )
	return ", ".join( names )


func _collect_names( record:Object, names:Array[String] ) -> void:
	if record == null:
		return
	var label:String = "root"
	if record.has_meta( &"layer_name" ):
		label = str( record.get_meta( &"layer_name" ) )
	names.append( label )
	var children:Array = record.get( &"children" )
	for child:Variant in children:
		var next:Object = child
		if next == null:
			continue
		_collect_names( next, names )
