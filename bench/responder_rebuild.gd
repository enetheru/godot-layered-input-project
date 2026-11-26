@tool
extends EditorScript

## BM_ResponderTreeRebuild times one [code]_rebuild_input_map[/code] on a tree that is
## already built. Each record contributes one action. That call composes the
## table again. An unchanged row stays, and the engine write follows the rows
## that changed.


const Fixture = preload( "res://bench/responder_fixture.gd" )
const RegisterLib = preload( "uid://ehhn1k7v0g6w" )
const Types = preload( "uid://bktkomkeaq1qm" )


func _run() -> void:
	Fixture.run( Callable( self, &"_register" ) )


func _register() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	var rebuild:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new( Callable( Fixture, &"BM_ResponderTreeRebuild" ) ) )
	rebuild = rebuild.ArgName( "n" ).Unit( Types.TimeUnit.kMillisecond ).UseRealTime().MinTime( 0.25 )
	for n:int in Fixture.REBUILD_SIZES:
		rebuild = rebuild.Arg( n )
