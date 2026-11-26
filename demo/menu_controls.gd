extends Node

##[codeblock lang=text]
##│ __  __                 ___         _           _
##│|  \/  |___ _ _ _  _   / __|___ _ _| |_ _ _ ___| |___
##│| |\/| / -_) ' \ || | | (__/ _ \ ' \  _| '_/ _ \ (_-<
##│|_|  |_\___|_||_\_,_|  \___\___/_||_\__|_| \___/_/__/
##╰───────────────────────────────────────────────────────
##[/codeblock]Pushes a menu responder and a clickable panel in front of gameplay.
##
## Call [method open] when the game wants this layer. [method close] takes it off again.
## The record is added as the link root's last child, so it is in front of play on the walk.
## Its map writes [code]jump[/code] with no events. The front write stays, so play's Space does not come back until this record is removed.
##
## [code]_input[/code] runs before the GUI. This callback marks the menu keys handled and leaves mouse buttons alone.
## [Button] then receives the click in the GUI pass and runs the same functions the keys run.


const ACTION_JUMP:StringName = &"jump"
const ACTION_CLOSE_MENU:StringName = &"close_menu"
const ACTION_CONFIRM:StringName = &"confirm"

const ResponderScript = preload( "res://addons/enetheru.layered-input/systems/responder.gd" )
const TreeViewScript = preload( "res://demo/tree_view.gd" )
const PlayControls = preload( "res://demo/play_controls.gd" )


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

## Gameplay object whose movement should pause while this menu is mounted.
var play:PlayControls

var _record:RefCounted
var _trace:TreeViewScript
var _layer:CanvasLayer
var _panel:PanelContainer
var _resume_button:Button
var _is_open:bool = false


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _ready() -> void:
	_mount()
	_build_panel()


## Keep the box a fixed pixel size on the right edge. A larger window moves it, and does not scale it.
func _process( _delta:float ) -> void:
	if not _is_open or _panel == null:
		return
	var view_size:Vector2 = get_viewport().get_visible_rect().size
	var height:float = maxf( _panel.size.y, 240.0 )
	_panel.position = Vector2( view_size.x - 336.0, view_size.y * 0.5 - height * 0.5 )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func set_trace( view:TreeViewScript ) -> void:
	_trace = view


#region Mount
#MARK: Mount
func                        __Mount__________________              ()->void:pass
# │ __  __              _
# │|  \/  |___ _  _ _ _| |_
# │| |\/| / _ \ || | ' \  _|
# │|_|  |_\___/\_,_|_||_\__|
# ╰──────────────────────────

## Keep the record unmounted until [method open]. Creating it here means open only links it.
func _mount() -> void:
	_record = ResponderScript.new()
	_record.set( &"input_map", _build_map() )
	_record.set( &"_input", Callable( self, &"_on_input" ) )
	_record.set_meta( &"layer_name", &"menu" )


func _build_map() -> CustomInputMap:
	var map:CustomInputMap = CustomInputMap.new()
	map.resource_name = "menu"
	_bind( map, ACTION_CLOSE_MENU, [KEY_ESCAPE] )
	_bind( map, ACTION_CONFIRM, [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] )
	# Same action name play uses. No events: while this record is in front, jump stays empty.
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


## Link the record and show the buttons. Play is asked to stop sampling movement.
func open() -> void:
	if _is_open:
		return
	InputManager.add_responder( _record )
	_is_open = true
	_layer.visible = true
	if play != null:
		play.set_movement_paused( true )
	_resume_button.grab_focus()


## Unlink the record and hide the buttons. Play samples movement again.
func close() -> void:
	if not _is_open:
		return
	InputManager.remove_responder( _record )
	_is_open = false
	_layer.visible = false
	if play != null:
		play.set_movement_paused( false )


## Close, and pulse the cube so the confirm is visible in the world.
func _resume() -> void:
	close()
	if play != null:
		play.pulse()


func _reset() -> void:
	if play != null:
		play.reset_place()

#endregion Mount


#region Panel
#MARK: Panel
func                        __Panel__________________              ()->void:pass
# │ ___               _
# │| _ \__ _ _ _  ___| |
# │|  _/ _` | ' \/ -_) |
# │|_| \__,_|_||_\___|_|
# ╰──────────────────────

## Ordinary [Control]s. Nothing here is a responder. Clicks arrive after [code]_input[/code] returns.
## The box is the only control on this layer, so a click on the yard or the tree is not taken by the menu.
func _build_panel() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 2
	add_child( _layer )

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size = Vector2( 280, 0 )
	_layer.add_child( _panel )

	var style:StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color( 0.08, 0.09, 0.12, 0.94 )
	style.set_corner_radius_all( 8 )
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override( &"panel", style )

	var box:VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override( &"separation", 10 )
	_panel.add_child( box )

	var title:Label = Label.new()
	title.text = "Menu"
	title.add_theme_font_size_override( &"font_size", 22 )
	box.add_child( title )

	var blurb:Label = Label.new()
	blurb.text = "Space resumes.\nReset puts the cube back."
	blurb.add_theme_font_size_override( &"font_size", 14 )
	box.add_child( blurb )

	_resume_button = _button( "Resume" )
	@warning_ignore("int_as_enum_without_cast")
	var _resume_hook:Error = _resume_button.pressed.connect( _resume )
	box.add_child( _resume_button )

	var reset:Button = _button( "Reset position" )
	@warning_ignore("int_as_enum_without_cast")
	var _reset_hook:Error = reset.pressed.connect( _reset )
	box.add_child( reset )
	_panel.reset_size()

	_layer.visible = false


func _button( label_text:String ) -> Button:
	var button:Button = Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2( 240, 40 )
	button.add_theme_font_size_override( &"font_size", 16 )
	return button

#endregion Panel


#region Keys
#MARK: Keys
func                        __Keys___________________              ()->void:pass
# │ _  __
# │| |/ /___ _  _ ___
# │| ' </ -_) || (_-<
# │|_|\_\___|\_, /__/
# ╰──────────|__/─────

## Keys are handled here, before [Button] sees them, so Space does not also activate the focused button.
## A mouse button counts as an action event. Marking it handled stops the click from reaching the button.
## Leave [InputEventMouse] for the GUI pass. Other actions are marked handled so play does not see them.
func _on_input( event:InputEvent ) -> void:
	var consumed:bool = false
	if event is InputEventMouse:
		pass
	elif _pressed( event, ACTION_CLOSE_MENU ):
		close()
		get_viewport().set_input_as_handled()
		consumed = true
	elif _pressed( event, ACTION_CONFIRM ):
		_resume()
		get_viewport().set_input_as_handled()
		consumed = true
	elif event.is_action_type():
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

#endregion Keys
