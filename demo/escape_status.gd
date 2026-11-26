extends Control

## Frame along the bottom of the window for the Escape row.
## The frame is as wide as the text, so the line is not clipped by the tree panel.


const TEXT_SIZE:int = 16
const PAD:float = 12.0
const MARGIN:float = 12.0

const TreeViewScript = preload( "res://demo/tree_view.gd" )

@onready var _tree_view:TreeViewScript = $"../TreeScroll/TreeView"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset( Control.PRESET_BOTTOM_LEFT )


func _process( _delta:float ) -> void:
	_fit()
	queue_redraw()


func _fit() -> void:
	var font:Font = ThemeDB.fallback_font
	if font == null or _tree_view == null:
		return
	var text:String = _tree_view.escape_line()
	var measured:Vector2 = font.get_string_size( text, HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_SIZE )
	var box_width:float = measured.x + PAD * 2.0
	var box_height:float = measured.y + PAD * 2.0
	offset_left = MARGIN
	offset_right = MARGIN + box_width
	offset_bottom = -MARGIN
	offset_top = -MARGIN - box_height


func _draw() -> void:
	var font:Font = ThemeDB.fallback_font
	if font == null or _tree_view == null:
		return
	var text:String = _tree_view.escape_line()
	draw_rect( Rect2( Vector2.ZERO, size ), Color( 0.05, 0.06, 0.08, 0.92 ) )
	var ascent:float = font.get_ascent( TEXT_SIZE )
	draw_string(
			font,
			Vector2( PAD, PAD + ascent ),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			TEXT_SIZE,
			Color( 0.93, 0.94, 0.96, 1 ) )
