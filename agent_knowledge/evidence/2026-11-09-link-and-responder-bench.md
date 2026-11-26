# Responder tree bench, 9 November and 26 November 2026

Four debug runs of the same sizes. The 9 November sample is `BM_LinkTreeRebuild` and `BM_LinkTreeWalk`. The 26 November samples are `BM_ResponderTreeRebuild` and `BM_ResponderTreeWalk`. Those families now live in `bench/responder_rebuild.gd` and `bench/responder_walk.gd`. The node-tree column from the first day belonged to an implementation that has been removed.

Each run used `godot.windows.editor.x86_64.llvm.tracy.exe` on 16 CPUs. The harness printed a clock of 0 MHz. The library was a debug build, and the log says those timings can be affected. Each family asked for 0.250 seconds of real time. The afternoon run is `2026-11-26T17:35:53`. The evening run is `2026-11-26T19:53:32`. The night run is `2026-11-26T23:35:45` for the rebuild and `2026-11-26T23:35:56` for the walk. The afternoon and evening runs each reported 7 benchmarks.

Rebuild times one `_rebuild_input_map` on a tree that is already built. Each record contributes one action. The afternoon call built a fresh table and copied the stock events on every pass. The evening call keeps the table. An unchanged stock row stays shared, and the engine write follows the rows that changed.

Walk times one `dispatch_input` through records that fill `_input` and carry no map. The timed loop leaves the map rebuild outside the sample. That path was left as it was between the two 26 November runs.

## Rebuild

| Size | 9 Nov | Iters | 17:35 | Iters | 19:53 | Iters | 23:35 | Iters |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 8 | 2.52 ms | 100 | 84.4 ms | 4 | 10.9 ms | 29 | 0.901 ms | 415 |
| 64 | 4.93 ms | 65 | 615 ms | 1 | 12.8 ms | 28 | 2.17 ms | 185 |
| 256 | 23.0 ms | 15 | 2809 ms | 1 | 18.4 ms | 22 | 7.09 ms | 52 |
| 1024 | 272 ms | 1 | 13362 ms | 1 | 37.1 ms | 10 | 28.4 ms | 14 |

The afternoon sample is the expensive one. At 8 it is about 33 times the 9 November time. At 64 and 256 it is about 120 times. At 1024 it is about 49 times, and both of those cells ran once. A guess that the evening numbers support: that sample paid a new action and a fresh event copy for every stock name on every call.

The evening sample drops that cost. Against the afternoon run it is about 8 times faster at 8, about 48 times at 64, about 150 times at 256, and about 360 times at 1024. Ten iterations at 1024 make that cell firmer than the single afternoon pass. Against 9 November, 256 and 1024 are faster (18.4 ms against 23.0 ms, 37.1 ms against 272 ms). The small sizes are still slower (10.9 ms against 2.52 ms, 12.8 ms against 4.93 ms). A guess: the remaining gap is the walk over the records and the stock names, which the 9 November tree did less of.

The night sample is faster than the evening one at every size. It is about 12 times faster at 8, about 6 times at 64, about 2.6 times at 256, and about 1.3 times at 1024. Against 9 November it is faster at every size: about 2.8 times at 8, about 2.3 times at 64, about 3.2 times at 256, and about 10 times at 1024. The timed call is still one full `_rebuild_input_map`.

## Walk

| Size | 9 Nov | Iters | 17:35 | Iters | 19:53 | Iters | 23:35 | Iters |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 128 | 0.084 ms | 4369 | 0.256 ms | 1237 | 0.259 ms | 1273 | 0.272 ms | 1372 |
| 1024 | 0.648 ms | 451 | 1.94 ms | 172 | 2.40 ms | 140 | 2.29 ms | 151 |
| 4096 | 2.58 ms | 100 | 9.65 ms | 35 | 10.4 ms | 34 | 9.81 ms | 31 |

The afternoon walk is about three times the 9 November time at 128 and 1024, and about four times at 4096. The evening walk sits on the afternoon one. The night walk sits on the evening one. All three stay near the growth of the record count. The pass calls captured callables from GDScript.
