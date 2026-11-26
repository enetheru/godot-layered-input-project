@tool
extends EditorScript

## BM_ResponderTreeWalk times one [code]dispatch_input[/code] of a key through N
## records. None of them mark the viewport handled, so the pass calls every
## captured callable. Those records carry no map, so the timed pass is the
## dispatch. The tree is built before the timed loop.


const Fixture = preload( "res://bench/responder_fixture.gd" )
const RegisterLib = preload( "uid://ehhn1k7v0g6w" )
const Types = preload( "uid://bktkomkeaq1qm" )

const WALK_SIZES:Array[int] = [128, 1024, 4096]


func _run() -> void:
	Fixture.run( Callable( self, &"_register" ) )


func _register() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	var walk:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new( BM_ResponderTreeWalk ) )
	walk = walk.ArgName( "n" ).Unit( Types.TimeUnit.kMillisecond ).UseRealTime().MinTime( 0.25 )
	for n:int in WALK_SIZES:
		walk = walk.Arg( n )


static func BM_ResponderTreeWalk( state:State ) -> void:
	var count:int = state.get_range( 0 )
	var fx:Fixture.TreeFixture = Fixture.TreeFixture.build( count, Fixture.Host.tree, false )
	if fx == null or fx.host == null or fx.responder_tree == null:
		state.SkipWithError( "no tree" )
		if fx != null:
			fx.free_tree()
		return

	var event:InputEventKey = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.pressed = true
	Fixture.LayerCall.visits = 0
	fx.responder_tree.dispatch_input( fx.host, event )
	if Fixture.LayerCall.visits != count:
		state.SkipWithError( "dispatch visited %d of %d" % [Fixture.LayerCall.visits, count] )
		fx.free_tree()
		return

	Fixture.LayerCall.visits = 0
	for _i in state:
		fx.responder_tree.dispatch_input( fx.host, event )
	fx.free_tree()
