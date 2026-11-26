extends GDSBenchExample

## A walk that calls every record. The family lives on [code]bench/responder_walk.gd[/code].


const Suite = preload( "res://bench/responder_walk.gd" )
const Fixture = preload( "res://bench/responder_fixture.gd" )
const Types = preload( "res://addons/enetheru.gdsbench/lib/types.gd" )

var _snapshot:CustomInputMap


func _register_benchmarks() -> void:
	Fixture.Host.tree = get_tree()
	var walk:Benchmark = explain(
			register_bm( Callable( Suite, &"BM_ResponderTreeWalk" ) )
					.ArgName( "n" )
					.Unit( Types.TimeUnit.kMillisecond )
					.UseRealTime()
					.MinTime( 0.25 ),
			"One dispatch_input through records that fill _input and carry no map.",
			{&"n": "responder count"} )
	for n:int in Suite.WALK_SIZES:
		walk = walk.Arg( n )


func _run_suite() -> void:
	_snapshot = CustomInputMap.engine_baseline()
	super._run_suite()
	var restore:Fixture.MapRestore = Fixture.MapRestore.new()
	restore.snapshot = _snapshot
	restore.arm( get_tree() )


func _exit_tree() -> void:
	super._exit_tree()
	Fixture.Host.tree = null
