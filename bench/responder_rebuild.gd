@tool
extends EditorScript

## BM_ResponderTreeRebuild times one [code]_rebuild_input_map[/code] on a tree that is
## already built. Each record contributes one action. That call composes the
## table again. An unchanged row stays, and the engine write follows the rows
## that changed.


const Fixture = preload( "res://bench/responder_fixture.gd" )
const RegisterLib = preload( "uid://ehhn1k7v0g6w" )
const Types = preload( "uid://bktkomkeaq1qm" )

const REBUILD_SIZES:Array[int] = [8, 64, 256, 1024]


func _run() -> void:
	Fixture.run( Callable( self, &"_register" ) )


func _register() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	var rebuild:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new( BM_ResponderTreeRebuild ) )
	rebuild = rebuild.ArgName( "n" ).Unit( Types.TimeUnit.kMillisecond ).UseRealTime().MinTime( 0.25 )
	for n:int in REBUILD_SIZES:
		rebuild = rebuild.Arg( n )


static func BM_ResponderTreeRebuild( state:State ) -> void:
	var count:int = state.get_range( 0 )
	var fx:Fixture.TreeFixture = Fixture.TreeFixture.build( count, Fixture.Host.tree, true )
	var built:CustomInputMap = Fixture.TreeFixture.map_of( fx.responder_tree ) if fx != null else null
	if fx == null or built == null:
		state.SkipWithError( "no tree" )
		if fx != null:
			fx.free_tree()
		return
	var tail:StringName = StringName( "li_%d" % ( count - 1 ) )
	if not built.has_action( tail ):
		state.SkipWithError( "rebuild did not keep %s" % tail )
		fx.free_tree()
		return
	for _i in state:
		fx.responder_tree._rebuild_input_map()
	fx.free_tree()
