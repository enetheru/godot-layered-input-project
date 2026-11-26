@tool
extends EditorScript

## BM_ResponderTreeWalk times one [code]dispatch_input[/code] of a key through N
## records. None of them mark the viewport handled, so the pass calls every
## captured callable. Those records carry no map, so the timed pass is the
## dispatch. The tree is built before the timed loop.


const Fixture = preload( "res://bench/responder_fixture.gd" )
const RegisterLib = preload( "uid://ehhn1k7v0g6w" )
const Types = preload( "uid://bktkomkeaq1qm" )


func _run() -> void:
	Fixture.run( Callable( self, &"_register" ) )


func _register() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	var walk:RegisterLib.Benchmark = RegisterLib.RegisterBenchmarkInternal(
			RegisterLib.FunctionBenchmark.new( Callable( Fixture, &"BM_ResponderTreeWalk" ) ) )
	walk = walk.ArgName( "n" ).Unit( Types.TimeUnit.kMillisecond ).UseRealTime().MinTime( 0.25 )
	for n:int in Fixture.WALK_SIZES:
		walk = walk.Arg( n )
