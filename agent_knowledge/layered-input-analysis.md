# Layered Input: Tracy duration comparison (corrected)

Date: 2026-11-09 (Australia/Adelaide).  
Working copy: `/home/box/projects/layered-input/Enetheru.layered-input-project - Copy`  
CSV exports (scratch): `/workspace/layered-input-tracy-csv-20261109/` via  
`/home/box/shared/godot/tracy-0.14.1-tools/csvexport/tracy-csvexport`  
(`total_ns` / `-e` self / `-u` unwrap / `-m` messages).

**Correction vs earlier draft:** first/last timestamps and zone *counts* do **not**
prove time dominance. This revision uses Tracy **inclusive totals**, **exclusive
self time**, and **per-event `exec_time_ns`**. Ranges are only used as phase
markers with message timestamps.

No project source was edited. Staging leftovers were not deleted.

---

## Implementations under comparison

| | Node tree (live autoload) | Link tree (unloaded slice) |
|---|---|---|
| Code | `systems/input_manager.gd`, `systems/responder.gd` | `link_tree/link_tree.gd`, `link_responder.gd` |
| Storage | SceneTree `Node`s | `RefCounted` parent/child lists |
| Rebuild | `_collect_maps` + `merge` (overwrite true) + `apply_to_engine` | reverse collect + `merge(..., false)` + `apply_to_engine` |
| Walk | Engine `Viewport.push_input` → node `_input*` | Cached walks + `dispatch_*` callables |
| Bench | `bench/responder_tree.gd` | `bench/link_tree.gd` |

Shared map stack: `CustomInputMap` / `InputAction` in `systems/`.

---

## Tooling and Tracy inputs

| Source | Status |
|---|---|
| `user-tracy` MCP | Unavailable (connector error). Not used. |
| `tracy-csvexport` 0.14.1 | Used for duration totals/self/unwrap/messages. |
| `trace-analyzer` | Zone inventory only; **no** duration totals. |
| Captures in archive | 40 `.tracy` under `tests/{node_tree,link_tree}/`. |

### What each capture class measures

| Class | Examples | Workload | Like-for-like? |
|---|---|---|---|
| Node stress rebuild | `test_tree_rebuild.tracy` (+ baseline) | 128 Node layers; markers `case:rebuild` | **No link twin** |
| Node stress walk | `test_tree_walk.tracy` (+ baseline) | 2048 Node layers; marker `case:walk` | **No link twin** |
| Correctness twins | 17 shared names (e.g. `test_handled`) | Tiny trees (few responders); correctness + one dispatch | Same *names*, not same *scale* as stress/bench |
| BenchLib evidence | `agent_knowledge/evidence/2026-11-09-link-and-responder-bench.md` | Rebuild 8/64/256/1024; walk 128/1024/4096 | Same sizes; walk mechanism differs; **no `.tracy` for those runs** |

Baseline stress files still reference old path `tests/responder_tree/...` inside zones;
treat as older Node snapshots, not a third implementation.

---

## BenchLib ms validation (evidence note)

Source code of benches:

- Both register with `.Unit(kMillisecond).UseRealTime().MinTime(0.25)`.
- `ConsoleReporter` prints **`GetAdjustedRealTime()` only** (`cpu_time` path commented out) — `console_reporter.gd` ~105–134.
- `timers.gd`: `ProcessCPUUsage` / `ThreadCPUUsage` **fall back to wall clock** in GDScript (no process CPU API).
- Reported values are **per-iteration means** (adjusted by dividing by iteration count). Different iteration counts at the same N are expected; comparing means is correct. Multiplying mean×iters recovers approximate total sample time, not a second metric.

Evidence caveats (from the note itself): debug tracy editor binary; CPU frequency printed **0 MHz**; “timings can be affected”. Treat as directional wall-time under profiling.

Recorded means (real time, per iteration):

**Rebuild**

| N | Link | Iters | Node | Iters |
|---:|---:|---:|---:|---:|
| 8 | 2.52 ms | 100 | 2.58 ms | 133 |
| 64 | 4.93 ms | 65 | 8.06 ms | 45 |
| 256 | 23.0 ms | 15 | 35.5 ms | 9 |
| 1024 | 272 ms | 1 | 303 ms | 1 |

**Walk**

| N | Link `dispatch_input` | Iters | Node `push_input` | Iters |
|---:|---:|---:|---:|---:|
| 128 | 0.084 ms | 4369 | 0.049 ms | 8004 |
| 1024 | 0.648 ms | 451 | 0.420 ms | 893 |
| 4096 | 2.58 ms | 100 | 1.93 ms | 180 |

Limits: single repetition; N=1024 rebuild only 1 iteration; walk paths are not the same code.

---

## Node stress Tracy: phase-isolated durations

Message timestamps (`-m`) used as phase gates (ns since capture start).

### A. `test_tree_rebuild.tracy` (128 layers)

Markers: `case:rebuild` @ 604.888 ms; two `_rebuild_input_map` events:

| Event | Start | Inclusive duration |
|---|---:|---:|
| rebuild #1 (post-construction deferred) | 389.402 ms | **215.383 ms** |
| rebuild #2 (`case:rebuild`) | 605.116 ms | **225.613 ms** |

Aggregate Tracy totals (whole capture, includes setup/teardown/physics await):

| Zone | Inclusive total | Exclusive self | Count | Notes |
|---|---:|---:|---:|---|
| `_rebuild_input_map` | 441.0 ms | 0.41 ms | 2 | Cost is almost all children |
| `merge` | 374.2 ms | 15.1 ms | 258 | ~129 merges × 2 rebuilds |
| `refresh_actions_inspector` | 263.6 ms | **258.1 ms** | 605 | Dominant **self** cost |
| `Resource.duplicate` (events, `input_action.gd:131`) | 79.4 ms | 79.4 ms | 452 | From `duplicate_action` |
| `Resource.duplicate` (map path `custom_input_map.gd:243`) | 61.5 ms | 61.5 ms | 225 | Event dup in `add_action` path |
| `duplicate_action` | 133.3 ms incl. | 14.4 ms self | 434 | Mostly child duplicates |
| `apply_to_engine` | 60.3 ms | 7.4 ms | 3 | |
| `_replace_action_in_engine` | 46.8 ms | 19.3 ms | 522 | |
| `_collect_maps` / `get_children` | ~8.0 / 0.7 ms | ~1.9 / 0.7 ms | 258 | **Not** the rebuild hotspot |

Per-event unwrap (`-u`) on `merge` during this capture:

- First merge in each rebuild wave ~28–32 ms (stock/default-sized map).
- Later merges ~0.7–1.9 ms, gently rising toward the end of the 128-layer wave.
- Splits: 129 merges before `case:rebuild` sum **193.5 ms**; 129 after sum **180.7 ms**.

`refresh_actions_inspector` after `case:rebuild`: early calls grow (~0.47 → ~1.92 ms by index ~104), consistent with copying a growing `_actions` dictionary; late calls (~0.04 ms) align with teardown/clear of small maps.

### B. `test_tree_walk.tracy` (2048 layers)

Marker: `case:walk` @ 2765.527 ms.

**Walk phase (measured):**

| Zone | Inclusive | Exclusive self | Count |
|---|---:|---:|---:|
| `Viewport.push_input` | **16.994 ms** | 2.490 ms | 1 |
| `_input` (handlers) in +50 ms window | ~31.5 ms sum* | — | 2048 (+1) |

\*Inclusive child sum can exceed parent; use **push_input inclusive 16.994 ms** as the walk envelope for this capture.

**After `case:walk` (deferred map rebuild — not the walk):**

| Zone | Inclusive sum | Mean | Count |
|---|---:|---:|---:|
| `merge` | **5347.4 ms** | 4.04 ms | 1324 |
| `refresh_actions_inspector` | **4795.2 ms** | 3.62 ms | 1324 |

Merge per-event growth after walk (unwrap): ~0.76 ms early → ~1.2 ms @100 → ~2.8 ms @500 → ~5.3 ms @1000 → ~7 ms at end. Approximate linear slope after first outlier: **~4.9 µs extra inclusive per successive merge index** (fits growing dict copy + duplicate work).

Whole-capture self leader: `refresh_actions_inspector` **4912.9 ms self (60.1%)**.

**Implication:** this 8 s capture is mostly **rebuild/setup**, not dispatch. Earlier drafts that inferred “merge dominates the walk” from first/last ranges were wrong.

---

## Mechanism (code + measured)

### 1. `merge` always ends with a full dict shallow-copy refresh

```436:445:addons/enetheru.layered-input/systems/custom_input_map.gd
func merge( other:CustomInputMap, overwrite:bool = true ) -> void:
	...
		_actions[action_name] = (
				ia.duplicate_action() if ia != null else null )
	refresh_actions_inspector()
```

```183:188:addons/enetheru.layered-input/systems/custom_input_map.gd
func refresh_actions_inspector() -> void:
	var copy:Dictionary[StringName, InputAction] = {}
	for k:StringName in _actions:
		copy[k] = _actions[k]
	_actions = copy
	notify_property_list_changed()
```

Assigning `_actions` also runs the export setter (`emit_changed`).  
`notify_property_list_changed` itself is tiny in Tracy (~0.1 ms total); the expensive self time is the **O(size) dictionary rebuild** inside `refresh_actions_inspector`.

During one full rebuild of N contributing layers into a growing effective map, that is **one refresh per merge**, with size 1…N (plus stock root actions) → **~O(N²) copy work**. Measured growth of merge/refresh durations with merge index supports this. This is **not** classical algorithmic quadratic inside `duplicate_action` alone; it is **repeated cumulative refreshing**.

`add_action` / `ensure_action_name` also call `refresh_actions_inspector` (setup path): rebuild capture has 605 refreshes vs 258 merges.

### 2. `duplicate_action` copies events via `Resource.duplicate`

```127:132:addons/enetheru.layered-input/systems/input_action.gd
func duplicate_action() -> InputAction:
	var out:InputAction = InputAction.new()
	out.deadzone = deadzone
	for ev:InputEvent in self:
		out.events.append( ev.duplicate() )
```

On N distinct single-event actions this is ~O(N) per rebuild **plus** whatever refreshes cost. Tracy self: event `Resource.duplicate` 79 ms (N≈128 rebuild) / 256 ms (walk capture rebuild wave).

### 3. Engine writes are real but smaller than refresh/merge at these sizes

`apply_to_engine` → `_replace_action_in_engine` (erase/add/add_event).  
Rebuild capture: apply inclusive 60 ms; `_replace_action_in_engine` self 19 ms. Important for correctness of the projection, secondary to inspector refresh in these **editor+tracy** captures.

### 4. SceneTree mount cost is real on Node construction, outside BenchLib timed rebuild

Enter-tree / `add_child` show large inclusive totals during `_build_tree`. BenchLib rebuild times a tree **already built**, so mount tax is excluded from those ms. Stress Tracy includes it.

### 5. `_collect_maps` / `Node.get_children` are cheap here

~0.7–8 ms totals at N=128. Mid-size BenchLib gap (link vs Node rebuild) is **unlikely** to be explained primarily by child-list walking; map compose/refresh is the Tracy-supported bottleneck on Node.

---

## Matched correctness twins (small)

Six name-matched pairs exported (`test_one_rebuild`, `test_handled`, `test_nested_order`, `test_pop`, `test_mid_pass`, `test_child_then_root`).

**Workload limits:** few responders; captures include fixture setup, default-map load, awaits, cleanup. They are **not** substitutes for N=256/1024 benches.

**Recurring measured pattern (both trees):**

- Top exclusive self: `refresh_actions_inspector` (~38–48 ms self on these small runs) and `Resource.duplicate` on the map/event paths.
- Node extras: `Node::_add_child_nocheck` / fixture `add_child` inclusive ~150 ms (SceneTree), nearly absent on link.
- Link extras: `until_rebuilt` / `rebuild_finished.await` inclusive waits; `dispatch_*` self for handled case ~0.1 ms (not a stress walk).

So small twins **agree** that map refresh/duplicate dominates shared code, and that Node pays SceneTree mount; they **do not** quantify large-N walk competition.

---

## Prioritized bottlenecks (measured → hypothesized)

1. **Repeated `refresh_actions_inspector` during runtime `merge` / structure edits** — **Measured** (top self in stress + twins; duration grows with map size). Editor-oriented API used on the hot rebuild path.  
2. **Per-layer `duplicate_action` + `Resource.duplicate` while composing effective map** — **Measured** (large inclusive under `merge`; solid self on duplicates). Necessary for isolation; amplified by (1).  
3. **Full `apply_to_engine` replace of every name each rebuild** — **Measured** (tens of ms at N=128; scales with action count). Secondary to (1)(2) in these traces.  
4. **Node SceneTree mount/teardown** — **Measured** in stress/setup; **excluded** from BenchLib rebuild sample. Matters for add/remove latency, not the timed `_rebuild_input_map` microbench.  
5. **Link GDScript dispatch vs Node engine walk** — **BenchLib only** (Node faster). Stress Tracy has no link walk twin at 2048. Do **not** over-generalize.  
6. **Profiling/debug overhead** — **Acknowledged**. All Tracy + evidence numbers are from tracy editor / debug-ish conditions; absolute ms will shrink on release, ranking may hold for (1)(2).

---

## Proposed optimizations (mechanism, tradeoffs, validation)

| Priority | Change | Expected mechanism | Tradeoffs | Validate with |
|---:|---|---|---|---|
| P0 | Silent merge path: skip `refresh_actions_inspector` (and avoid `_actions` setter/`emit_changed`) when composing ephemeral `effective_map` | Removes O(N) copy per layer → drops O(N²) refresh; Tracy self of refresh should collapse on rebuild | Must not break Inspector authoring; needs explicit “runtime compose” API | Re-run `test_tree_rebuild` Tracy + BenchLib rebuild; compare refresh self and rebuild means |
| P0 | Batch refresh once after all merges in `_rebuild_input_map` (if inspector notify still desired) | One O(N) copy instead of N | Easy footgun if merge used elsewhere expecting refresh | Same as above; also small twin still edits maps in editor tests |
| P1 | Avoid duplicating unchanged `InputAction` rows when overwrite-false skip already keeps them; consider COW / share immutable rows | Less `duplicate_action` / `Resource.duplicate` | Lifetime/aliasing bugs if a layer mutates a shared action | Tracy self on `duplicate_action`; correctness suite |
| P1 | Delta `apply_to_engine` (only dirty names) | Cuts InputMap erase/add churn | Stale engine actions if dirty set wrong | Tracy `_replace_action_in_engine` self; gameplay binding checks |
| P2 | Keep studying link tree for mount/order without declaring ship | May remove SceneTree mount tax | Migration cost; walk currently slower in BenchLib | Need link stress Tracy twins + release BenchLib |
| P2 | Hybrid (link maps + engine walk) | Chase BenchLib’s best of both | Dual bookkeeping | New benches only — not evidenced yet |

**Explicit non-conclusion:** evidence does **not** justify “ship the link tree now.” Link rebuild means are better in one debug BenchLib pair; Node walk means are better; large-N Tracy exists only for Node; shared map refresh tax hits **both** once they call `merge`.

---

## Validation plan (no new user data required to start; listed for when available)

1. Keep using `tracy-csvexport -e` / `-u` on existing captures (done for this note).  
2. When possible: link-tree stress twins at N=128/2048 with same markers; BenchLib under Tracy; release binary with valid CPU MHz.  
3. After a P0 silent-merge patch: expect rebuild Tracy `refresh_actions_inspector` self ≪ current; BenchLib rebuild means to drop especially at 64–256.  
4. Re-check walk BenchLib after any dispatch change; keep Node `push_input` inclusive ~17 ms @2048 as a Tracy reference point under tracy-editor conditions.

---

## Paths and leftovers

**Kept**

- Persistent: `/cursor/stores/store-56b2d957-c839-4d97-8aaf-29e31526a368/archives/Enetheru.layered-input-project.zip`  
- Persistent extract + read-only home copy as previously reported  
- This note: `/home/box/projects/helloworld-admin/layered-input-analysis.md`

**Scratch CSVs (await delete approval)**

- `/workspace/layered-input-tracy-csv-20261109/`  
- Prior staging ZIPs unchanged:
  - `/workspace/Enetheru.layered-input-project-20261109-staging.zip`
  - `C:\Users\nicho\grok-box\Enetheru.layered-input-project-20261109-staging.zip`
