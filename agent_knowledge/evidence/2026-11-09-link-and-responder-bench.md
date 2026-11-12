# Link and responder benches, 9 November 2026

The link rebuild is faster at every measured size. The responder walk is faster at every measured size. This file records one debug pair.

## The two runs

The link run is `2026-11-09T01:55:00`. The responder run is `2026-11-09T01:56:00`. Both used `godot.windows.editor.x86_64.llvm.tracy.exe` on 16 CPUs. The harness printed a clock of 0 MHz, so the frequency was unread. The library was a debug build, and the log says those timings can be affected. Each family asked for 0.250 seconds of real time. Each run reported 7 benchmarks.

## What the clocks include

`BM_LinkTreeRebuild` and `BM_ResponderTreeRebuild` each time one `{gdscript} _rebuild_input_map` on a tree that is already built. The sizes are 8, 64, 256, and 1024. On the link tree each record contributes one action, the merge walks from the front with overwrite false, and the call writes the engine map. On the responder tree the merge walks forward and a later map overwrites the same action name, and the call writes the engine map. The responder tree is the live node tree.

`BM_LinkTreeWalk` times one `{gdscript} dispatch_input` through records that fill `{gdscript} _input` and carry no map. `BM_ResponderTreeWalk` times one key pushed through the engine group. The sizes are 128, 1024, and 4096. On both sides the timed loop leaves the map rebuild outside the sample.

## Rebuild

| Size | Link | Iterations | Responder | Iterations |
|---:|---:|---:|---:|---:|
| 8 | 2.52 ms | 100 | 2.58 ms | 133 |
| 64 | 4.93 ms | 65 | 8.06 ms | 45 |
| 256 | 23.0 ms | 15 | 35.5 ms | 9 |
| 1024 | 272 ms | 1 | 303 ms | 1 |

At 8 the samples meet, 2.52 ms and 2.58 ms. A guess: that shared floor is the stock root map, which both trees fold before the extra layers add much. At 64 the link sample is 4.93 ms and the responder sample is 8.06 ms. At 256 the samples are 23.0 ms and 35.5 ms. At 1024 they are 272 ms and 303 ms, and each of those two ran once.

From 256 to 1024 the layer count grows fourfold. The link time grows about twelvefold and the responder time about ninefold. Each layer contributes a distinct action name, so the front-first skip still copies every layer name. A guess: the climb belongs to the merge and the engine write, and the gap at 64 and 256 belongs to collecting records rather than nodes. The single iteration at 1024 is a thin sample for that guess.

## Walk

| Size | Link | Iterations | Responder | Iterations |
|---:|---:|---:|---:|---:|
| 128 | 0.084 ms | 4369 | 0.049 ms | 8004 |
| 1024 | 0.648 ms | 451 | 0.420 ms | 893 |
| 4096 | 2.58 ms | 100 | 1.93 ms | 180 |

From 128 to 4096 both walks stay near the growth of the record count. At 4096 the link sample is 2.58 ms and the responder sample is 1.93 ms. The link pass calls captured callables from GDScript. The responder pass is the engine group walk.
