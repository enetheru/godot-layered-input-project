extends Node3D

##[codeblock lang=text]
##│ __  __      _
##│|  \/  |__ _(_)_ _
##│| |\/| / _` | | ' \
##│|_|  |_\__,_|_|_||_|
##╰──────────────────────
##[/codeblock]Wires the cube, the inventory, and the menu.
##
## [code]demo/play_controls.gd[/code] is the gameplay responder. [code]demo/inventory_controls.gd[/code] hangs under it. [code]demo/menu_controls.gd[/code] is pushed on the root.


const TreeViewScript = preload( "res://demo/tree_view.gd" )
const PlayControls = preload( "res://demo/play_controls.gd" )
const MenuControls = preload( "res://demo/menu_controls.gd" )
const InventoryControls = preload( "res://demo/inventory_controls.gd" )


# ██████  ██████   ██████  ██████  ███████ ██████  ████████ ██ ███████ ███████ #
# ██   ██ ██   ██ ██    ██ ██   ██ ██      ██   ██    ██    ██ ██      ██      #
# ██████  ██████  ██    ██ ██████  █████   ██████     ██    ██ █████   ███████ #
# ██      ██   ██ ██    ██ ██      ██      ██   ██    ██    ██ ██           ██ #
# ██      ██   ██  ██████  ██      ███████ ██   ██    ██    ██ ███████ ███████ #
func                        ________PROPERTIES_______              ()->void:pass

@onready var _play:PlayControls = $PlayControls
@onready var _menu:MenuControls = $MenuControls
@onready var _inventory:InventoryControls = $InventoryControls
@onready var _tree_view:TreeViewScript = $Hud/TreeScroll/TreeView


#      ██████  ██    ██ ███████ ██████  ██████  ██ ██████  ███████ ███████     #
#     ██    ██ ██    ██ ██      ██   ██ ██   ██ ██ ██   ██ ██      ██          #
#     ██    ██ ██    ██ █████   ██████  ██████  ██ ██   ██ █████   ███████     #
#     ██    ██  ██  ██  ██      ██   ██ ██   ██ ██ ██   ██ ██           ██     #
#      ██████    ████   ███████ ██   ██ ██   ██ ██ ██████  ███████ ███████     #
func                        ________OVERRIDES________              ()->void:pass

## Point the two control scripts at each other.
func _ready() -> void:
	_play.set_trace( _tree_view )
	_menu.set_trace( _tree_view )
	_inventory.set_trace( _tree_view )
	_menu.play = _play
	_inventory.play = _play
	@warning_ignore("int_as_enum_without_cast")
	var _menu_hook:Error = _play.menu_requested.connect( _menu.open )
	@warning_ignore("int_as_enum_without_cast")
	var _inventory_hook:Error = _play.inventory_requested.connect( _inventory.open )
