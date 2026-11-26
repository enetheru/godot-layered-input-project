# Responder tree bench, 9 November and 26 November 2026

Two debug runs of the same sizes. The 9 November sample is `BM_LinkTreeRebuild` and `BM_LinkTreeWalk`. The 26 November sample is `BM_ResponderTreeRebuild` and `BM_ResponderTreeWalk` in `bench/responder_tree.gd`. The node-tree column from the first day belonged to an implementation that has been removed.

Both runs used `godot.windows.editor.x86_64.llvm.tracy.exe` on 16 CPUs. The harness printed a clock of 0 MHz. The library was a debug build, and the log says those timings can be affected. Each family asked for 0.250 seconds of real time. The 26 November run is `2026-11-26T17:35:53` and reported 7 benchmarks.

Rebuild times one `_rebuild_input_map` on a tree that is already built. Each record contributes one action. The merge walks from the front with overwrite false, and the call writes the engine map.

Walk times one `dispatch_input` through records that fill `_input` and carry no map. The timed loop leaves the map rebuild outside the sample.

## Rebuild

| Size | 9 Nov | Iterations | 26 Nov | Iterations |
|---:|---:|---:|---:|---:|
| 8 | 2.52 ms | 100 | 84.4 ms | 4 |
| 64 | 4.93 ms | 65 | 615 ms | 1 |
| 256 | 23.0 ms | 15 | 2809 ms | 1 |
| 1024 | 272 ms | 1 | 13362 ms | 1 |

At 8 the later sample is about 33 times the earlier one. At 64 and 256 it is about 120 times. At 1024 it is about 49 times, and both of those cells ran once. A guess: the later rebuild pays the stock-map event copies on every call, and that cost was smaller or absent on 9 November. The single iteration above 8 on the later run is a thin sample.

## Walk

| Size | 9 Nov | Iterations | 26 Nov | Iterations |
|---:|---:|---:|---:|---:|
| 128 | 0.084 ms | 4369 | 0.256 ms | 1237 |
| 1024 | 0.648 ms | 451 | 1.94 ms | 172 |
| 4096 | 2.58 ms | 100 | 9.65 ms | 35 |

The later walk is about three times the earlier one at 128 and 1024, and about four times at 4096. Both stay near the growth of the record count. The pass calls captured callables from GDScript.
