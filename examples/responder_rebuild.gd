extends GDSBenchExample

## Warm full compose. The family lives on [code]bench/responder_rebuild.gd[/code].


const Suite = preload( "res://bench/responder_rebuild.gd" )
const Fixture = preload( "res://bench/responder_fixture.gd" )
const Types = preload( "res://addons/enetheru.gdsbench/lib/types.gd" )

var _snapshot:CustomInputMap


func _register_benchmarks() -> void:
	Fixture.Host.tree = get_tree()
	var rebuild:Benchmark = explain(
			register_bm( Callable( Suite, &"BM_ResponderTreeRebuild" ) )
					.ArgName( "n" )
					.Unit( Types.TimeUnit.kMillisecond )
					.UseRealTime()
					.MinTime( 0.25 ),
			"One full compose of a tree that is already built. Each record contributes one action.",
			{&"n": "responder count"} )
	for n:int in Suite.REBUILD_SIZES:
		rebuild = rebuild.Arg( n )


func _run_suite() -> void:
	_snapshot = CustomInputMap.engine_baseline()
	super._run_suite()
	var restore:Fixture.MapRestore = Fixture.MapRestore.new()
	restore.snapshot = _snapshot
	restore.arm( get_tree() )


func _exit_tree() -> void:
	super._exit_tree()
	Fixture.Host.tree = null
