@tool
extends EditorScript

## Cost of one dispatch through the link tree.
##
## BM_LinkTreeWalk times one dispatch_input of a key through N records.
## None of them mark the viewport handled, so the pass calls every
## captured callable. The tree is built before the timed loop.
## The node bench times the engine walk and the map rebuild. This bench
## times the link walk.


const RegisterLib = preload( "uid://ehhn1k7v0g6w" )
const Types = preload( "uid://bktkomkeaq1qm" )
const ConsoleReporter = preload( "uid://cp6jwltd8s2ur" )
const LinkTreeScript = preload( "../addons/enetheru.layered-input/link_tree/link_tree.gd" )
const LinkResponderScript = preload( "../addons/enetheru.layered-input/link_tree/link_responder.gd" )

const WALK_SIZES:Array[int] = [128, 1024, 4096]


class Host:
	static var tree:SceneTree


class LayerCall:
	static var visits:int = 0


	static func on_input( _ev:InputEvent ) -> void:
		visits += 1


func _run() -> void:
	var tree:SceneTree = _editor_tree()
	if tree == null:
		printerr( "link tree bench: no SceneTree" )
		return
	Host.tree = tree

	var saved_dry:bool = BenchLib.FLAGS_benchmark_dry_run
	var saved_min_time:String = BenchLib.FLAGS_benchmark_min_time
	var saved_reps:int = BenchLib.FLAGS_benchmark_repetitions

	BenchLib.FLAGS_benchmark_dry_run = false
	BenchLib.FLAGS_benchmark_min_time = "0.25s"
	BenchLib.FLAGS_benchmark_repetitions = 1
	_register()

	var reporter:ConsoleReporter = ConsoleReporter.new()
	var n:int = BenchLib.RunSpecifiedBenchmarks( reporter )
	print( "%d benchmarks" % n )

	_sweep( tree )
	RegisterLib.ClearRegisteredBenchmarks()
	BenchLib.FLAGS_benchmark_dry_run = saved_dry
	BenchLib.FLAGS_benchmark_min_time = saved_min_time
	BenchLib.FLAGS_benchmark_repetitions = saved_reps
	Host.tree = null


func _register() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	var walk:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new( BM_LinkTreeWalk ) )
	walk = walk.ArgName( "n" ).Unit( Types.TimeUnit.kMillisecond ).UseRealTime().MinTime( 0.25 )
	for n:int in WALK_SIZES:
		walk = walk.Arg( n )


func _editor_tree() -> SceneTree:
	var base:Control = EditorInterface.get_base_control()
	if base == null:
		return null
	return base.get_tree()


static func BM_LinkTreeWalk( state:State ) -> void:
	var count:int = state.get_range( 0 )
	var fx:TreeFixture = TreeFixture.build( count, Host.tree )
	if fx == null or fx.host == null or fx.link_tree == null:
		state.SkipWithError( "no tree" )
		if fx != null:
			fx.free_tree()
		return

	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	LayerCall.visits = 0
	fx.link_tree.call( &"dispatch_input", fx.host, event )
	if LayerCall.visits != count:
		state.SkipWithError( "dispatch visited %d of %d" % [LayerCall.visits, count] )
		fx.free_tree()
		return

	LayerCall.visits = 0
	for _i in state:
		fx.link_tree.call( &"dispatch_input", fx.host, event )
	fx.free_tree()


func _sweep( tree:SceneTree ) -> void:
	var leftover:Node = tree.root.get_node_or_null( "LinkTreeBench" )
	if is_instance_valid( leftover ):
		leftover.free()


class TreeFixture:
	var host:SubViewport
	var link_tree:RefCounted


	static func build( count:int, tree:SceneTree ) -> TreeFixture:
		if tree == null:
			return null
		var fx := TreeFixture.new()
		var vp := SubViewport.new()
		vp.name = "LinkTreeBench"
		vp.disable_3d = true
		vp.size = Vector2i( 2, 2 )
		vp.handle_input_locally = true
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child( vp )

		var created:RefCounted = LinkTreeScript.new()
		var root:Object = created.get( &"root" )
		if root == null:
			vp.free()
			return null
		var input_call := Callable( LayerCall, &"on_input" )
		for _i:int in count:
			var record:RefCounted = LinkResponderScript.new()
			record.set( &"_input", input_call )
			root.call( &"add_responder", record )

		fx.host = vp
		fx.link_tree = created
		return fx


	func free_tree() -> void:
		if is_instance_valid( host ):
			host.free()
		host = null
		link_tree = null
