extends Node

##[codeblock lang=text]
##│ ___                 _
##│|_ _|_ ___ _____ _ _| |_ ___ _ _ _  _
##│ | || ' \ V / -_) ' \  _/ _ \ '_| || |
##│|___|_||_\_/\___|_||_\__\___/_|  \_, |
##╰─────────────────────────────────|__/───
##[/codeblock]A player layer for a fake inventory. Tab or Escape closes it.
##
## The record is a child of play, so it sits in front of play and behind a menu pushed on the root.
## Escape is marked handled here, so the same press does not open the menu.
##[br][br]
## While the menu is in front, the menu already consumes keys, so Tab and Escape close the menu first and leave this layer mounted.


const ACTION_INVENTORY:StringName = &"inventory"
const ACTION_OPEN_MENU:StringName = &"open_menu"

const Responder = preload( "uid://cjpmfrvsqx7jo" )
const TreeViewScript = preload( "res://demo/tree_view.gd" )
const PlayControls = preload( "res://demo/play_controls.gd" )


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

## Player this layer hangs under.
var play:PlayControls

var _record:Responder
var _trace:TreeViewScript
var _layer:CanvasLayer
var _panel:PanelContainer
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


## Fixed pixel box, to the right of the tree panel and clear of the menu.
func _process( _delta:float ) -> void:
	if not _is_open or _panel == null:
		return
	var view_size:Vector2 = get_viewport().get_visible_rect().size
	var width:float = maxf( _panel.size.x, 280.0 )
	var height:float = maxf( _panel.size.y, 220.0 )
	var x:float = maxf( view_size.x * 0.5 - width * 0.5, 496.0 )
	var menu_left:float = view_size.x - 348.0
	if x + width > menu_left:
		x = maxf( menu_left - width, 496.0 )
	_panel.position = Vector2( x, view_size.y * 0.5 - height * 0.5 )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

func set_trace( view:TreeViewScript ) -> void:
	_trace = view


## Hang the record under play and show the fake sheet.
func open() -> void:
	if _is_open or play == null:
		return
	play.attach_layer( _record )
	_is_open = true
	_layer.visible = true
	play.set_inventory_paused( true )


## Take the record off play. The menu, if it is open, stays open.
func close() -> void:
	if not _is_open or play == null:
		return
	play.detach_layer( _record )
	_is_open = false
	_layer.visible = false
	play.set_inventory_paused( false )


func _mount() -> void:
	_record = Responder.new()
	_record.input_map = _build_map()
	_record._input = _on_input
	_record.set_meta( &"layer_name", &"inventory" )


func _build_map() -> CustomInputMap:
	var map:CustomInputMap = CustomInputMap.new()
	map.resource_name = "inventory"
	# Tab and Escape close this layer. Empty open_menu is written while this record is in front, so play's Escape does not stay.
	var events:Array[InputEvent] = []
	events.append( _key( KEY_TAB ) )
	events.append( _key( KEY_ESCAPE ) )
	var _inventory_action:InputAction = map.add_action( ACTION_INVENTORY, CustomInputMap.DEFAULT_DEADZONE, events )
	var _open_menu:InputAction = map.add_action( ACTION_OPEN_MENU )
	return map


func _key( code:Key ) -> InputEventKey:
	var event:InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	return event


func _build_panel() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 2
	add_child( _layer )

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.custom_minimum_size = Vector2( 280, 0 )
	_layer.add_child( _panel )

	var style:StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color( 0.10, 0.12, 0.11, 0.94 )
	style.set_corner_radius_all( 8 )
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override( &"panel", style )

	var box:VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override( &"separation", 8 )
	_panel.add_child( box )

	var title:Label = Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override( &"font_size", 22 )
	box.add_child( title )

	for line:String in [ "Health  100", "Stamina  40", "Gold  12", "Weapon  Wooden sword" ]:
		var row:Label = Label.new()
		row.text = line
		row.add_theme_font_size_override( &"font_size", 16 )
		box.add_child( row )

	var close_button:Button = Button.new()
	close_button.text = "Close"
	close_button.custom_minimum_size = Vector2( 240, 40 )
	close_button.add_theme_font_size_override( &"font_size", 16 )
	@warning_ignore( "int_as_enum_without_cast" )
	var _close_hook:Error = close_button.pressed.connect( close )
	box.add_child( close_button )
	_panel.reset_size()
	_layer.visible = false


## Tab and Escape close the sheet. Mouse clicks reach the Close button. Every other key falls through.
func _on_input( event:InputEvent ) -> void:
	var consumed:bool = false
	if event is InputEventMouse:
		pass
	elif _pressed( event, ACTION_INVENTORY ):
		close()
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
