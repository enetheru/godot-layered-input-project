extends Control

##[codeblock lang=text]
##│ _____             __   ___
##│|_   _| _ ___ ___  \ \ / (_)_____ __ __
##│  | || '_/ -_) -_)  \ V /| / -_) V  V /
##│  |_||_| \___\___|   \_/ |_\___|\_/\_/
##╰─────────────────────────────────────────
##[/codeblock]Draws the link tree, the walks, and which layer kept each action name.
##
## Reads [code]InputManager.tree[/code] each frame. The demo calls [method note_dispatch] when a callback runs.


const PANEL_MARGIN:float = 8.0
const TITLE_SIZE:int = 20
const BODY_SIZE:int = 15
const SMALL_SIZE:int = 13

const TEXT:Color = Color( 0.93, 0.94, 0.96, 1 )
const DIM:Color = Color( 0.68, 0.71, 0.76, 1 )
const CLAIM:Color = Color( 0.93, 0.78, 0.42, 1 )
const PANEL:Color = Color( 0.05, 0.06, 0.08, 0.92 )
const CARD_ROOT:Color = Color( 0.16, 0.17, 0.2, 1 )
const CARD_PLAY:Color = Color( 0.12, 0.28, 0.42, 1 )
const CARD_MENU:Color = Color( 0.38, 0.24, 0.12, 1 )
const CARD_INVENTORY:Color = Color( 0.18, 0.32, 0.24, 1 )
const CHIP_IDLE:Color = Color( 0.2, 0.21, 0.24, 1 )
const CHIP_PASSED:Color = Color( 0.18, 0.4, 0.62, 1 )
const CHIP_CONSUMED:Color = Color( 0.72, 0.34, 0.16, 1 )
const CHIP_SKIPPED:Color = Color( 0.14, 0.14, 0.16, 1 )

## Action names this scene is built to show.
const WATCHED:Array[StringName] = [
	&"jump",
	&"move_left",
	&"confirm",
	&"open_menu",
	&"inventory",
	&"ui_accept",
]

const WALK_SLOTS:Array[StringName] = [
	&"_input",
	&"_shortcut_input",
	&"_unhandled_key_input",
	&"_unhandled_input",
]


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

var _trace_event:InputEvent
var _trace_label:String = ""
var _trace_ids:Array[int] = []
var _trace_consumed:Array[bool] = []
var _shot_ids:Array[int] = []
var _shot_names:Array[String] = []

## False while measuring the panel height. Draw calls stay quiet.
var _ink:bool = true


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process( _delta:float ) -> void:
	queue_redraw()


func _draw() -> void:
	if size.x < 32.0:
		return

	var font:Font = ThemeDB.fallback_font
	if font == null:
		return

	var panel:Rect2 = Rect2( PANEL_MARGIN, PANEL_MARGIN, size.x - PANEL_MARGIN * 2.0, 0.0 )
	var left:float = panel.position.x + 14.0
	var width:float = panel.size.x - 28.0
	var top:float = panel.position.y + 14.0

	_ink = false
	var bottom:float = _layout( font, left, width, top )
	panel.size.y = bottom + 12.0 - panel.position.y

	_ink = true
	_fill( panel, PANEL )
	var _painted:float = _layout( font, left, width, top )

	var need:float = panel.end.y + PANEL_MARGIN
	if not is_equal_approx( custom_minimum_size.y, need ):
		custom_minimum_size = Vector2( 0.0, need )


func _layout( font:Font, left:float, width:float, y:float ) -> float:
	y = _draw_title( font, left, width, y )
	y = _draw_links( font, left, width, y )
	y = _draw_walks( font, left, width, y )
	y = _draw_names( font, left, width, y )
	return y


func _fill( rect:Rect2, color:Color ) -> void:
	if not _ink:
		return
	draw_rect( rect, color )


func _text(
			font:Font,
			pos:Vector2,
			text:String,
			width:float,
			font_size:int,
			color:Color ) -> void:
	if not _ink:
		return
	draw_string(
			font,
			pos,
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			width,
			font_size,
			color )


#         ███    ███ ███████ ████████ ██   ██  ██████  ██████  ███████         #
#         ████  ████ ██         ██    ██   ██ ██    ██ ██   ██ ██              #
#         ██ ████ ██ █████      ██    ███████ ██    ██ ██   ██ ███████         #
#         ██  ██  ██ ██         ██    ██   ██ ██    ██ ██   ██      ██         #
#         ██      ██ ███████    ██    ██   ██  ██████  ██████  ███████         #
func                        _________METHODS_________              ()->void:pass

#region Notes
#MARK: Notes
func                        __Notes__________________              ()->void:pass
# │ _  _     _
# │| \| |___| |_ ___ ___
# │| .` / _ \  _/ -_|_-<
# │|_|\_\___/\__\___/__/
# ╰──────────────────────

## Records one callback from the demo. The first note for an event copies the [code]_input[/code] walk.
func note_dispatch( record:RefCounted, event:InputEvent, consumed:bool ) -> void:
	if record == null or event == null:
		return
	if _skip_event( event ):
		return
	if event != _trace_event:
		_begin_trace( event )

	_trace_ids.append( record.get_instance_id() )
	_trace_consumed.append( consumed )


func _begin_trace( event:InputEvent ) -> void:
	_trace_event = event
	_trace_label = _event_text( event )
	_trace_ids.clear()
	_trace_consumed.clear()
	_shot_ids.clear()
	_shot_names.clear()

	var tree:Object = _link_tree()
	if tree == null:
		return

	var raw:Variant = tree.get( &"input_walk" )
	if raw is not Array:
		return

	var walk:Array = raw
	for item:Variant in walk:
		if item is not Object:
			continue
		var record:Object = item
		if record == null:
			continue
		_shot_ids.append( record.get_instance_id() )
		_shot_names.append( _record_name( record ) )


func _skip_event( event:InputEvent ) -> bool:
	if event.is_echo():
		return true
	if event is InputEventMouseMotion:
		return true
	if event is InputEventJoypadMotion:
		return true
	if event is InputEventScreenDrag:
		return true
	return false


func _trace_sentence() -> String:
	if _trace_label == "":
		return "Press a key. This line is the _input walk for that event."

	if _shot_ids.is_empty():
		return "%s on _input: no callbacks" % _trace_label

	var parts:PackedStringArray = PackedStringArray()
	var stopped:bool = false
	var _added:bool = false
	for index:int in _shot_ids.size():
		var id:int = _shot_ids[index]
		var who:String = _shot_names[index]
		var at:int = _trace_ids.find( id )
		if stopped or at < 0:
			_added = parts.append( "%s skipped" % who )
		elif _trace_consumed[at]:
			_added = parts.append( "%s consumed" % who )
			stopped = true
		else:
			_added = parts.append( "%s passed" % who )

	return "%s on _input: %s" % [ _trace_label, ", ".join( parts ) ]

#endregion Notes


#region Draw
#MARK: Draw
func                        __Draw___________________              ()->void:pass
# │ ___
# │|   \ _ _ __ ___ __ __
# │| |) | '_/ _` \ V  V /
# │|___/|_| \__,_|\_/\_/
# ╰───────────────────────

func _draw_title( font:Font, left:float, width:float, y:float ) -> float:
	y = _line( font, "Responder tree", TITLE_SIZE, TEXT, left, width, y )
	y = _line(
			font,
			"WASD moves. Space jumps. Tab opens inventory.",
			SMALL_SIZE,
			DIM,
			left,
			width,
			y )
	y = _line( font, "Escape closes inventory, or opens the menu.", SMALL_SIZE, DIM, left, width, y )
	return y + 6.0


func _draw_links( font:Font, left:float, width:float, y:float ) -> float:
	y = _line(
			font,
			"Links. Drawn parent, then children.",
			SMALL_SIZE,
			CLAIM,
			left,
			width,
			y )

	var root:Object = _root()
	if root == null:
		return _line( font, "(no root)", BODY_SIZE, DIM, left, width, y ) + 8.0

	y = _draw_record( font, root, 0, left, width, y )
	return y + 8.0


func _draw_record(
			font:Font,
			record:Object,
			depth:int,
			left:float,
			width:float,
			y:float ) -> float:
	var indent:float = float( depth ) * 18.0
	var rect:Rect2 = Rect2( left + indent, y, maxf( 40.0, width - indent ), 42.0 )
	var label:String = _record_name( record )
	var active:bool = _flag( record, &"active" )
	_fill( rect, _card_color( label, active ) )

	var mark:Color = _trace_mark( record.get_instance_id() )
	if mark.a > 0.0:
		_fill( Rect2( rect.position, Vector2( 4.0, rect.size.y ) ), mark )

	var title:String = _indexed_name( record )
	if not active:
		title += "  inactive"
	var slots:String = _slot_tags( record )
	if slots != "":
		title += "  " + slots

	var text_y:float = rect.position.y + 4.0
	var text_w:float = rect.size.x - 16.0
	text_y = _line( font, title, BODY_SIZE, TEXT, rect.position.x + 10.0, text_w, text_y )
	var _detail_y:float = _line(
			font,
			_card_detail( font, record, text_w ),
			SMALL_SIZE,
			DIM,
			rect.position.x + 10.0,
			text_w,
			text_y )

	y = rect.end.y + 6.0
	var raw:Variant = record.get( &"children" )
	if raw is not Array:
		return y

	var kids:Array = raw
	for child_v:Variant in kids:
		if child_v is not Object:
			continue
		var child:Object = child_v
		if child == null:
			continue
		y = _draw_record( font, child, depth + 1, left, width, y )

	return y


func _draw_walks( font:Font, left:float, width:float, y:float ) -> float:
	y = _line(
			font,
			"Walks. Last child first. This list is the tree reversed.",
			SMALL_SIZE,
			CLAIM,
			left,
			width,
			y )
	y = _line(
			font,
			"That puts the last child at 0. 0 sees the event first.",
			SMALL_SIZE,
			CLAIM,
			left,
			width,
			y )

	var tree:Object = _link_tree()
	if tree == null:
		return y + 8.0

	for slot:StringName in WALK_SLOTS:
		y = _draw_walk_row( font, tree, slot, left, width, y )

	y += 4.0
	y = _line( font, _trace_sentence(), SMALL_SIZE, TEXT, left, width, y )
	y = _line(
			font,
			"Orange consumed. Blue passed. Dim was not called.",
			SMALL_SIZE,
			DIM,
			left,
			width,
			y )
	return y + 8.0


func _draw_walk_row(
			font:Font,
			tree:Object,
			slot:StringName,
			left:float,
			width:float,
			y:float ) -> float:
	var ascent:float = font.get_ascent( SMALL_SIZE )
	var slot_label:String = String( slot )
	var slot_px:float = font.get_string_size(
			slot_label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			SMALL_SIZE ).x
	_text( font, Vector2( left, y + ascent ), slot_label, width, SMALL_SIZE, DIM )

	var walk:Array = _walk( tree, slot )
	var x:float = left + slot_px + 12.0
	var limit:float = left + width
	if walk.is_empty():
		_text( font, Vector2( x, y + ascent ), "(empty)", 120.0, SMALL_SIZE, DIM )
		return y + 24.0

	var stopped:bool = false
	for index:int in walk.size():
		var item:Variant = walk[index]
		if item is not Object:
			continue
		var record:Object = item
		if record == null:
			continue

		var id:int = record.get_instance_id()
		var who:String = "%d:%s" % [ index, _record_name( record ) ]
		var chip_w:float = maxf(
				52.0,
				font.get_string_size( who, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_SIZE ).x + 14.0 )
		if x + chip_w > limit:
			break

		var fill:Color = CHIP_IDLE
		var ink:Color = TEXT
		var at:int = _trace_ids.find( id )
		if stopped and _shot_ids.has( id ):
			fill = CHIP_SKIPPED
			ink = DIM
		elif at >= 0 and at < _trace_consumed.size() and _trace_consumed[at]:
			fill = CHIP_CONSUMED
			stopped = true
		elif at >= 0:
			fill = CHIP_PASSED

		var chip:Rect2 = Rect2( x, y, chip_w, 18.0 )
		_fill( chip, fill )
		if index == 0:
			_fill( Rect2( x, y, chip_w, 3.0 ), CLAIM )
		_text( font, Vector2( x + 7.0, y + ascent ), who, chip_w - 10.0, SMALL_SIZE, ink )
		x += chip_w + 6.0

	return y + 24.0


## The Escape row for the status frame. The actions that still have it, front of the walk first.
func escape_line() -> String:
	var root:Object = _root()
	if root == null:
		return "Escape  (none)"
	return _key_line( KEY_ESCAPE, _contributors( root ), _effective_map() )


func _key_line( code:Key, layers:Array[Object], effective:CustomInputMap ) -> String:
	var label:String = OS.get_keycode_string( code )
	if effective == null:
		return "%s  (none)" % label

	var parts:PackedStringArray = PackedStringArray()
	var _added:bool = false
	for action:StringName in _actions_with_key( effective, code, layers ):
		_added = parts.append( "%s %s" % [ _keeper_name( action, layers ), action ] )
	if parts.is_empty():
		return "%s  (none)" % label
	return "%s  %s" % [ label, " · ".join( parts ) ]


func _actions_with_key(
			effective:CustomInputMap,
			code:Key,
			layers:Array[Object] ) -> Array[StringName]:
	var found:Array[StringName] = []
	for action:StringName in effective.get_action_names():
		if _map_has_key( effective, action, code ):
			found.append( action )
	return _sort_by_keeper( found, layers )


func _sort_by_keeper( actions:Array[StringName], layers:Array[Object] ) -> Array[StringName]:
	var ordered:Array[StringName] = []
	var ranks:Array[int] = []
	for action:StringName in actions:
		var rank:int = _keeper_index( action, layers )
		var at:int = ordered.size()
		for index:int in ordered.size():
			if rank < ranks[index]:
				at = index
				break
		var _placed:int = ordered.insert( at, action )
		var _ranked:int = ranks.insert( at, rank )
	return ordered


func _keeper_name( action:StringName, layers:Array[Object] ) -> String:
	for record:Object in layers:
		var map:CustomInputMap = _record_map( record )
		if map != null and map.has_action( action ):
			return _indexed_name( record )
	return "baseline"


func _keeper_index( action:StringName, layers:Array[Object] ) -> int:
	var index:int = 0
	for record:Object in layers:
		var map:CustomInputMap = _record_map( record )
		if map != null and map.has_action( action ):
			var at:int = _input_index( record )
			if at >= 0:
				return at
			return index
		index += 1
	return 1000


func _map_has_key( map:CustomInputMap, action:StringName, code:Key ) -> bool:
	for event:InputEvent in map.get_action_events( action ):
		if event is InputEventKey:
			var key:InputEventKey = event as InputEventKey
			var got:Key = key.physical_keycode
			if got == KEY_NONE:
				got = key.keycode
			if got == code:
				return true
	return false


func _draw_names( font:Font, left:float, width:float, y:float ) -> float:
	y = _line(
			font,
			"Actions. Each row is one action name in the merged map.",
			SMALL_SIZE,
			CLAIM,
			left,
			width,
			y )
	y = _line(
			font,
			"0 writes the name first. kept stays. lost was written later.",
			SMALL_SIZE,
			CLAIM,
			left,
			width,
			y )

	var root:Object = _root()
	if root == null:
		return y

	var layers:Array[Object] = _contributors( root )
	var effective:CustomInputMap = _effective_map()
	for action:StringName in WATCHED:
		y = _line( font, _name_row( action, layers, effective ), SMALL_SIZE, TEXT, left, width, y )
	y = _line( font, _baseline_sentence( layers, effective ), SMALL_SIZE, DIM, left, width, y )
	return y


func _line(
			font:Font,
			text:String,
			font_size:int,
			color:Color,
			left:float,
			width:float,
			y:float ) -> float:
	var ascent:float = font.get_ascent( font_size )
	var descent:float = font.get_descent( font_size )
	_text( font, Vector2( left, y + ascent ), text, width, font_size, color )
	return y + ascent + descent + 3.0


func _card_color( label:String, active:bool ) -> Color:
	var color:Color = CARD_ROOT
	if label == "play":
		color = CARD_PLAY
	elif label == "menu":
		color = CARD_MENU
	elif label == "inventory":
		color = CARD_INVENTORY
	if not active:
		color = color.darkened( 0.45 )
	return color


func _trace_mark( id:int ) -> Color:
	var at:int = _trace_ids.find( id )
	if at < 0 or at >= _trace_consumed.size():
		return Color( 0, 0, 0, 0 )
	if _trace_consumed[at]:
		return CHIP_CONSUMED
	return CHIP_PASSED

#endregion Draw


#region Read
#MARK: Read
func                        __Read___________________              ()->void:pass
# │ ___             _
# │| _ \___ __ _ __| |
# │|   / -_) _` / _` |
# │|_|_\___\__,_\__,_|
# ╰────────────────────

func _link_tree() -> Object:
	var raw:Variant = InputManager.get( &"tree" )
	if raw is Object:
		var tree:Object = raw
		return tree
	return null


func _root() -> Object:
	var tree:Object = _link_tree()
	if tree == null:
		return null
	var raw:Variant = tree.get( &"root" )
	if raw is Object:
		var root:Object = raw
		return root
	return null


func _effective_map() -> CustomInputMap:
	var tree:Object = _link_tree()
	if tree == null:
		return null
	var raw:Variant = tree.get( &"effective_map" )
	if raw is CustomInputMap:
		return raw
	return null


func _input_index( record:Object ) -> int:
	var tree:Object = _link_tree()
	if tree == null or record == null:
		return -1
	var walk:Array = _walk( tree, &"_input" )
	var id:int = record.get_instance_id()
	for index:int in walk.size():
		var item:Variant = walk[index]
		if item is not Object:
			continue
		var other:Object = item
		if other != null and other.get_instance_id() == id:
			return index
	return -1


func _walk( tree:Object, slot:StringName ) -> Array:
	var prop:StringName = &"unhandled_input_walk"
	if slot == &"_input":
		prop = &"input_walk"
	elif slot == &"_shortcut_input":
		prop = &"shortcut_input_walk"
	elif slot == &"_unhandled_key_input":
		prop = &"unhandled_key_input_walk"

	var raw:Variant = tree.get( prop )
	if raw is Array:
		return raw
	return []


func _contributors( root:Object ) -> Array[Object]:
	var ordered:Array[Object] = []
	_collect_contributors( root, ordered )
	ordered.reverse()
	return ordered


func _collect_contributors( record:Object, out:Array[Object] ) -> void:
	if _contributes( record ):
		out.append( record )

	var raw:Variant = record.get( &"children" )
	if raw is not Array:
		return

	var kids:Array = raw
	for child_v:Variant in kids:
		if child_v is not Object:
			continue
		var child:Object = child_v
		if child == null:
			continue
		_collect_contributors( child, out )


func _contributes( record:Object ) -> bool:
	return record.call( &"contributes_map" ) == true


func _record_name( record:Object ) -> String:
	if record.has_meta( &"layer_name" ):
		return str( record.get_meta( &"layer_name" ) )
	return "root"


func _record_map( record:Object ) -> CustomInputMap:
	var raw:Variant = record.get( &"input_map" )
	if raw is CustomInputMap:
		return raw
	return null


func _card_detail( font:Font, record:Object, width:float ) -> String:
	var map:CustomInputMap = _record_map( record )
	var map_text:String = "no map"
	if map != null:
		var names:Array[StringName] = map.get_action_names()
		if names.size() > 6:
			map_text = "stock map · %d actions" % names.size()
		elif names.size() > 3:
			map_text = "%d actions" % names.size()
		elif names.is_empty():
			map_text = "empty map"
		else:
			map_text = _fit_actions( font, map, names, width )

	if _slot_tags( record ) == "":
		return map_text + " · no callbacks"
	return map_text


func _fit_actions(
			font:Font,
			map:CustomInputMap,
			names:Array[StringName],
			width:float ) -> String:
	var ordered:Array[StringName] = []
	if names.has( &"jump" ):
		ordered.append( &"jump" )
	for action:StringName in names:
		if action != &"jump":
			ordered.append( action )

	var built:String = ""
	for action:StringName in ordered:
		var piece:String = "%s %s" % [ action, _events_label( map, action, 2 ) ]
		var candidate:String = piece
		if built != "":
			candidate = built + ", " + piece
		var wide:float = font.get_string_size(
				candidate,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				SMALL_SIZE ).x
		if wide > width:
			if built == "":
				return "%d actions" % names.size()
			return built
		built = candidate
	return built


func _slot_tags( record:Object ) -> String:
	var parts:PackedStringArray = PackedStringArray()
	var _added:bool = false
	if _slot_filled( record, &"_input" ):
		_added = parts.append( "input" )
	if _slot_filled( record, &"_shortcut_input" ):
		_added = parts.append( "shortcut" )
	if _slot_filled( record, &"_unhandled_key_input" ):
		_added = parts.append( "key" )
	if _slot_filled( record, &"_unhandled_input" ):
		_added = parts.append( "unhandled" )
	return " ".join( parts )


func _slot_filled( record:Object, slot:StringName ) -> bool:
	var raw:Variant = record.get( slot )
	if raw is not Callable:
		return false
	var cb:Callable = raw
	return cb.is_valid()


func _name_row(
			action:StringName,
			layers:Array[Object],
			effective:CustomInputMap ) -> String:
	var parts:PackedStringArray = PackedStringArray()
	var kept:bool = true
	var _added:bool = false
	for record:Object in layers:
		var map:CustomInputMap = _record_map( record )
		if map == null or not map.has_action( action ):
			continue
		var who:String = _indexed_name( record )
		var events:String = _events_label( map, action )
		if kept:
			_added = parts.append( "%s %s kept" % [ who, events ] )
			kept = false
		else:
			_added = parts.append( "%s %s lost" % [ who, events ] )

	if parts.is_empty():
		if effective != null and effective.has_action( action ):
			return "%s  baseline %s" % [ action, _events_label( effective, action ) ]
		return "%s  (absent)" % action

	return "%s  %s" % [ action, " · ".join( parts ) ]


func _events_label( map:CustomInputMap, action:StringName, limit:int = 3 ) -> String:
	var events:Array[InputEvent] = map.get_action_events( action )
	if events.is_empty():
		return "(none)"

	var labels:PackedStringArray = PackedStringArray()
	var _added:bool = false
	var shown:int = mini( events.size(), limit )
	for index:int in shown:
		_added = labels.append( _event_text( events[index] ) )
	if events.size() > shown:
		_added = labels.append( "+%d" % ( events.size() - shown ) )
	return ", ".join( labels )


func _event_text( event:InputEvent ) -> String:
	if event is InputEventKey:
		var key:InputEventKey = event as InputEventKey
		var code:Key = key.physical_keycode
		if code == KEY_NONE:
			code = key.keycode
		return OS.get_keycode_string( code )
	return event.as_text()


func _baseline_sentence( layers:Array[Object], effective:CustomInputMap ) -> String:
	var count:int = _baseline_count( layers, effective )
	if count == 0:
		return "The startup engine map added no names. The responders already wrote them."
	return "The startup engine map added %d names the responders left empty." % count


func _baseline_count( layers:Array[Object], effective:CustomInputMap ) -> int:
	if effective == null:
		return 0

	var written:Dictionary[StringName, bool] = {}
	for record:Object in layers:
		var map:CustomInputMap = _record_map( record )
		if map == null:
			continue
		for action:StringName in map.get_action_names():
			written[action] = true

	var extra:int = 0
	for action:StringName in effective.get_action_names():
		if not written.has( action ):
			extra += 1
	return extra


func _indexed_name( record:Object ) -> String:
	var label:String = _record_name( record )
	var at:int = _input_index( record )
	if at < 0:
		return label
	return "%d:%s" % [ at, label ]


func _flag( record:Object, prop:StringName ) -> bool:
	return record.get( prop ) == true

#endregion Read
