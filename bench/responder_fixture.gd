@tool
extends RefCounted

## Tree, viewport, and engine-map restore shared by the responder benches.
##
## Construction queues a deferred rebuild. [MapRestore] writes the engine map
## back on the next process frame, after that deferred call applies.


const RegisterLib = preload( "uid://ehhn1k7v0g6w" )
const ConsoleReporter = preload( "uid://cp6jwltd8s2ur" )
const ResponderTree = preload( "res://addons/enetheru.layered-input/systems/responder_tree.gd" )
const Responder = preload( "res://addons/enetheru.layered-input/systems/responder.gd" )


class Host:
	static var tree:SceneTree


class LayerCall:
	static var visits:int = 0


	static func on_input( _ev:InputEvent ) -> void:
		visits += 1


# The bench needs a SceneTree to hang the viewport on. The editor has one. A template player does too.
static func editor_tree() -> SceneTree:
	if OS.has_feature( "editor" ):
		var base:Control = EditorInterface.get_base_control()
		if base != null:
			return base.get_tree()
	var loop:MainLoop = Engine.get_main_loop()
	if loop is SceneTree:
		var scene_tree:SceneTree = loop
		return scene_tree
	return null


# Runs one family's register callback, then puts the engine map back.
static func run( register:Callable ) -> void:
	var tree:SceneTree = editor_tree()
	if tree == null:
		printerr( "responder bench: no SceneTree" )
		return
	Host.tree = tree

	var saved_dry:bool = BenchLib.FLAGS_benchmark_dry_run
	var saved_min_time:String = BenchLib.FLAGS_benchmark_min_time
	var saved_reps:int = BenchLib.FLAGS_benchmark_repetitions
	var snapshot:CustomInputMap = CustomInputMap.engine_baseline()

	BenchLib.FLAGS_benchmark_dry_run = false
	BenchLib.FLAGS_benchmark_min_time = "0.25s"
	BenchLib.FLAGS_benchmark_repetitions = 1
	register.call()

	var reporter:ConsoleReporter = ConsoleReporter.new()
	var n:int = BenchLib.RunSpecifiedBenchmarks( reporter )
	print( "%d benchmarks" % n )

	sweep( tree )
	var restore:MapRestore = MapRestore.new()
	restore.snapshot = snapshot
	restore.arm( tree )
	RegisterLib.ClearRegisteredBenchmarks()
	BenchLib.FLAGS_benchmark_dry_run = saved_dry
	BenchLib.FLAGS_benchmark_min_time = saved_min_time
	BenchLib.FLAGS_benchmark_repetitions = saved_reps
	Host.tree = null


static func sweep( tree:SceneTree ) -> void:
	var leftover:Node = tree.root.get_node_or_null( "ResponderBench" )
	if is_instance_valid( leftover ):
		leftover.free()


class MapRestore:
	var snapshot:CustomInputMap
	var _tree:SceneTree


	func arm( tree:SceneTree ) -> void:
		if tree == null:
			return
		_tree = tree
		var _bound:int = _tree.process_frame.connect( _apply )


	func _apply() -> void:
		if _tree != null and _tree.process_frame.is_connected( _apply ):
			_tree.process_frame.disconnect( _apply )
		_tree = null
		if is_instance_valid( InputManager ) and InputManager.tree != null:
			var root:Responder = InputManager.tree.root
			if root != null:
				root.input_map = _InputManager.get_default_input_map()
		if not is_instance_valid( snapshot ):
			return
		for action_name:StringName in InputMap.get_actions():
			if not snapshot.has_action( action_name ):
				InputMap.erase_action( action_name )
		snapshot.apply_to_engine()


class TreeFixture:
	var host:SubViewport
	var responder_tree:ResponderTree


	static func map_of( owner:ResponderTree ) -> CustomInputMap:
		if owner == null:
			return null
		return owner.effective_map


	static func _layer_map( index:int ) -> CustomInputMap:
		var map:CustomInputMap = CustomInputMap.new()
		var ev:InputEventKey = InputEventKey.new()
		ev.keycode = KEY_A
		ev.pressed = true
		var events:Array[InputEvent] = []
		events.append( ev )
		var _row:InputAction = map.add_action( StringName( "li_%d" % index ), 0.2, events )
		return map


	static func build( count:int, tree:SceneTree, rebuild:bool = false ) -> TreeFixture:
		if tree == null:
			return null
		var fx:TreeFixture = TreeFixture.new()
		var vp:SubViewport = SubViewport.new()
		vp.name = "ResponderBench"
		vp.disable_3d = true
		vp.size = Vector2i( 2, 2 )
		vp.handle_input_locally = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child( vp )

		var created:ResponderTree = ResponderTree.new()
		var root:Responder = created.root
		if root == null:
			vp.free()
			return null
		if rebuild:
			for i:int in count:
				var record:Responder = Responder.new()
				record.input_map = _layer_map( i )
				root.add_responder( record )
			created._rebuild_input_map()
		else:
			var input_call:Callable = Callable( LayerCall, &"on_input" )
			for _i:int in count:
				var record:Responder = Responder.new()
				record._input = input_call
				root.add_responder( record )

		fx.host = vp
		fx.responder_tree = created
		return fx


	func free_tree() -> void:
		if is_instance_valid( host ):
			host.free()
		host = null
		responder_tree = null
