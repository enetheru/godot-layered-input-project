extends Control

##[codeblock]
##│  ___ ___  ___ ___              _    ___                     _     _  _      _
##│ / __|   \/ __| _ ) ___ _ _  __| |_ | __|_ ____ _ _ __  _ __| |___| || |_  _| |__
##│| (_ | |) \__ \ _ \/ -_) ' \/ _| ' \| _|\ \ / _` | '  \| '_ \ / -_) __ | || | '_ \
##│ \___|___/|___/___/\___|_||_\__|_||_|___/_\_\__,_|_|_|_| .__/_\___|_||_|\_,_|_.__/
##│                                                       |_|
##╰────────────────────────────────────────────────────────────────────────────────────
##[/codeblock] Index of this project's benches.
##
## Table of suites. Activate a row (Enter / double-click) or press Open.
## The project main scene stays the yard. Run this scene with F6.

const EXAMPLES:Array[Dictionary] = [
	{&"title": "Responder rebuild",
			&"path": "res://examples/responder_rebuild.tscn",
			&"blurb": "Warm full compose. Each record contributes one action."},
	{&"title": "Responder walk",
			&"path": "res://examples/responder_walk.tscn",
			&"blurb": "One dispatch_input. Every record runs."},
]


@onready var _list:Tree = %List
@onready var _open_btn:Button = %Open


func _ready() -> void:
	var tree:Tree = _list
	tree.columns = 2
	tree.set_column_title(0, "Example")
	tree.set_column_title(1, "Measures")
	tree.set_column_expand(0, false)
	tree.set_column_custom_minimum_width(0, 200)
	tree.set_column_expand(1, true)
	tree.clear()
	var root:TreeItem = tree.create_item()
	for entry:Dictionary in EXAMPLES:
		var title:String = entry[&"title"]
		var path:String = entry[&"path"]
		var blurb:String = entry[&"blurb"]
		var item:TreeItem = tree.create_item(root)
		item.set_text(0, title)
		item.set_text(1, blurb)
		item.set_metadata(0, path)
	var first:TreeItem = root.get_first_child()
	if first != null:
		first.select(0)
	var _a:int = tree.item_activated.connect(_on_activated)
	var _o:int = _open_btn.pressed.connect(_on_open_pressed)


func _on_activated() -> void:
	_open_selected()


func _on_open_pressed() -> void:
	_open_selected()


func _open_selected() -> void:
	var item:TreeItem = _list.get_selected()
	if item == null:
		return
	var path:String = item.get_metadata(0)
	if path.is_empty() or not ResourceLoader.exists(path):
		push_error("missing example scene: %s" % path)
		return
	var _err:int = get_tree().change_scene_to_file(path)
