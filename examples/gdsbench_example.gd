class_name GDSBenchExample
extends Control

##[codeblock]
##│  ___ ___  ___ ___              _    ___                     _
##│ / __|   \/ __| _ ) ___ _ _  __| |_ | __|_ ____ _ _ __  _ __| |___
##│| (_ | |) \__ \ _ \/ -_) ' \/ _| ' \| _|\ \ / _` | '  \| '_ \ / -_)
##│ \___|___/|___/___/\___|_||_\__|_||_|___/_\_\__,_|_|_|_| .__/_\___|
##│                                                       |_|
##╰─────────────────────────────────────────────────────────────────────
##[/codeblock] Runnable GDSBench example scene.
##
## Play with F6 or set as the export main scene. Override
## [method _register_benchmarks] to add families. The play view is a
## table; the editor log still gets the console reporter.
## [br]
## User args after [code]--[/code]: [code]--spec=[/code],
## [code]--min-time=[/code], [code]--dry-run[/code], [code]--quit[/code].

const RegisterLib = preload("res://addons/enetheru.gdsbench/lib/benchmark_register.gd")
const ScreenReporter = preload("res://examples/screen_reporter.gd")

const Benchmark = RegisterLib.Benchmark
const FunctionBenchmark = RegisterLib.FunctionBenchmark

const HUB_SCENE:String = "res://examples/hub.tscn"

@export var title:String = ""
@export var spec:String = "."
@export var min_time:String = "0.1s"
@export var dry_run:bool = false
@export var quit_on_finish:bool = false

@onready var _title_lbl:Label = %Title
@onready var _meta_lbl:Label = %Meta
@onready var _notice_lbl:Label = %Notice
@onready var _results:Tree = %Results
@onready var _status_lbl:Label = %Status
@onready var _back_btn:Button = %Back
@onready var _run_btn:Button = %Run

const HEAT_BEST:Color = Color(0.16, 0.38, 0.26)
const HEAT_MID:Color = Color(0.32, 0.28, 0.12)
const HEAT_WORST:Color = Color(0.42, 0.16, 0.16)

var _saved_list:bool
var _saved_dry:bool
var _saved_min_time:String
var _saved_reps:int
var _flags_saved:bool = false
var _col_ids:PackedStringArray = PackedStringArray()
var _col_bases:PackedStringArray = PackedStringArray()
var _lower_better:Dictionary = {}
var _name_help:Dictionary = {}


func _ready() -> void:
	_apply_user_args()
	if not title.is_empty():
		_title_lbl.text = title
	elif _title_lbl.text.is_empty():
		var scr:Script = get_script()
		_title_lbl.text = scr.resource_path.get_file().get_basename()
	var _c1:int = _back_btn.pressed.connect(_on_back_pressed)
	var _c2:int = _run_btn.pressed.connect(_on_run_pressed)
	var _c3:int = _results.column_title_clicked.connect(_on_column_title_clicked)
	_run_suite()


func _exit_tree() -> void:
	RegisterLib.ClearRegisteredBenchmarks()
	_restore_flags()


func _register_benchmarks() -> void:
	pass


func register_bm(fn:Callable, bm_name:String = "") -> Benchmark:
	return RegisterLib.RegisterBenchmarkInternal(
			FunctionBenchmark.new(fn, bm_name))


func explain(
		bm:Benchmark,
		blurb:String,
		args:Dictionary = {}
) -> Benchmark:
	var args_s:Dictionary = {}
	for k:Variant in args.keys():
		var ks:String = str(k)
		args_s[ks] = args[k]
	_name_help[bm.GetName()] = {&"blurb": blurb, &"args": args_s}
	return bm


func _on_back_pressed() -> void:
	if ResourceLoader.exists(HUB_SCENE):
		var _err:int = get_tree().change_scene_to_file(HUB_SCENE)
	else:
		get_tree().quit()


func _on_run_pressed() -> void:
	_run_suite()


func _apply_user_args() -> void:
	for arg:String in OS.get_cmdline_user_args():
		if arg.begins_with("--spec="):
			spec = arg.trim_prefix("--spec=")
		elif arg.begins_with("--min-time="):
			min_time = arg.trim_prefix("--min-time=")
		elif arg == "--dry-run":
			dry_run = true
		elif arg == "--quit":
			quit_on_finish = true


func _save_flags() -> void:
	if _flags_saved:
		return
	_saved_list = BenchLib.FLAGS_benchmark_list_tests
	_saved_dry = BenchLib.FLAGS_benchmark_dry_run
	_saved_min_time = BenchLib.FLAGS_benchmark_min_time
	_saved_reps = BenchLib.FLAGS_benchmark_repetitions
	_flags_saved = true


func _restore_flags() -> void:
	if not _flags_saved:
		return
	BenchLib.FLAGS_benchmark_list_tests = _saved_list
	BenchLib.FLAGS_benchmark_dry_run = _saved_dry
	BenchLib.FLAGS_benchmark_min_time = _saved_min_time
	BenchLib.FLAGS_benchmark_repetitions = _saved_reps
	_flags_saved = false


func _run_suite() -> void:
	_save_flags()
	RegisterLib.ClearRegisteredBenchmarks()
	BenchLib.FLAGS_benchmark_list_tests = false
	BenchLib.FLAGS_benchmark_dry_run = dry_run
	if not min_time.is_empty():
		BenchLib.FLAGS_benchmark_min_time = min_time
	_name_help.clear()
	_register_benchmarks()
	var reporter:ScreenReporter = ScreenReporter.new()
	reporter.name_help = _name_help
	var n:int = BenchLib.RunSpecifiedBenchmarks(reporter, null, spec)
	reporter.finish()
	_fill_table(reporter, n)
	if quit_on_finish:
		get_tree().quit()


func _fill_table(reporter:ScreenReporter, n:int) -> void:
	var extras:PackedStringArray = reporter.extra_keys
	var cols:int = 3 + extras.size()
	_col_ids = PackedStringArray(["", "time", "iters"])
	_col_bases = PackedStringArray(["Benchmark", "Time", "Iters"])
	_ensure_sense("time", true)
	_ensure_sense("iters", false)
	_results.clear()
	_results.columns = cols
	_results.set_column_expand(0, true)
	_results.set_column_expand(1, false)
	_results.set_column_expand(2, false)
	_results.set_column_custom_minimum_width(1, 120)
	_results.set_column_custom_minimum_width(2, 80)
	_results.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
	_results.set_column_title_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)
	for i:int in extras.size():
		var col:int = 3 + i
		var key:String = extras[i]
		var _id:int = _col_ids.append(key)
		var _b:int = _col_bases.append(reporter.extra_title(key))
		_ensure_sense(key, reporter.guess_lower_better(key))
		_results.set_column_expand(col, false)
		_results.set_column_custom_minimum_width(col, 128)
		_results.set_column_title_alignment(col, HORIZONTAL_ALIGNMENT_RIGHT)
	_refresh_titles()
	var root:TreeItem = _results.create_item()
	for row:ScreenReporter.Row in reporter.rows:
		var item:TreeItem = _results.create_item(root)
		var ok:bool = row.note.is_empty() \
				and row.time != "error" and row.time != "skipped"
		item.set_text(0, row.name)
		if not row.tooltip.is_empty():
			item.set_tooltip_text(0, row.tooltip)
		item.set_text(1, row.time)
		item.set_text(2, row.iters)
		item.set_text_alignment(1, HORIZONTAL_ALIGNMENT_RIGHT)
		item.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)
		if ok:
			item.set_metadata(1, row.seconds)
			item.set_metadata(2, float(row.iters_n))
		for i:int in extras.size():
			var key:String = extras[i]
			var cell:String = ""
			if row.extras.has(key):
				cell = row.extras[key]
			elif not row.note.is_empty() and i == 0:
				cell = row.note
			item.set_text(3 + i, cell)
			item.set_text_alignment(3 + i, HORIZONTAL_ALIGNMENT_RIGHT)
			if ok and row.extra_values.has(key):
				var ev:float = row.extra_values[key]
				item.set_metadata(3 + i, ev)
		if extras.is_empty() and not row.note.is_empty():
			item.set_tooltip_text(1, row.note)
	_apply_heatmap()
	var meta_parts:PackedStringArray = PackedStringArray()
	if not reporter.context_line.is_empty():
		var _c:int = meta_parts.append(reporter.context_line)
	var _r:int = meta_parts.append(
			"%d run%s" % [n, "" if n == 1 else "s"])
	if spec != "." and spec != "all":
		var _s:int = meta_parts.append("filter %s" % spec)
	_meta_lbl.text = " · ".join(meta_parts)
	if reporter.notices.is_empty() and reporter.errors.is_empty():
		_notice_lbl.visible = false
		_notice_lbl.text = ""
	else:
		_notice_lbl.visible = true
		var bits:PackedStringArray = PackedStringArray()
		bits.append_array(reporter.notices)
		bits.append_array(reporter.errors)
		_notice_lbl.text = "\n".join(bits)
	_status_lbl.text = "Green better, red worse. Click a header to flip ↑/↓."


func _ensure_sense(id:String, lower_default:bool) -> void:
	if not _lower_better.has(id):
		_lower_better[id] = lower_default


func _is_lower_better(id:String) -> bool:
	if _lower_better.has(id):
		return _lower_better[id]
	return true


func _refresh_titles() -> void:
	for col:int in _col_bases.size():
		var base:String = _col_bases[col]
		if col == 0:
			_results.set_column_title(col, base)
			continue
		var mark:String = "↓" if _is_lower_better(_col_ids[col]) else "↑"
		_results.set_column_title(col, "%s  %s" % [base, mark])


func _on_column_title_clicked(column:int, mouse_button_index:int) -> void:
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	if column <= 0 or column >= _col_ids.size():
		return
	var id:String = _col_ids[column]
	_lower_better[id] = not _is_lower_better(id)
	_refresh_titles()
	_apply_heatmap()


func _apply_heatmap() -> void:
	var root:TreeItem = _results.get_root()
	if root == null:
		return
	var items:Array[TreeItem] = []
	var child:TreeItem = root.get_first_child()
	while child != null:
		items.append(child)
		child = child.get_next()
	for col:int in range(1, _results.columns):
		_color_column(items, col)


func _color_column(items:Array[TreeItem], col:int) -> void:
	var vals:Array[float] = []
	for item:TreeItem in items:
		var raw:Variant = item.get_metadata(col)
		if raw is float:
			var n:float = raw
			if is_finite(n):
				vals.append(n)
	if vals.size() < 2:
		for item:TreeItem in items:
			item.clear_custom_bg_color(col)
		return
	var lo:float = vals[0]
	var hi:float = vals[0]
	for n:float in vals:
		lo = minf(lo, n)
		hi = maxf(hi, n)
	if is_equal_approx(lo, hi):
		for item:TreeItem in items:
			item.clear_custom_bg_color(col)
		return
	var lower:bool = true
	if col < _col_ids.size():
		lower = _is_lower_better(_col_ids[col])
	var span:float = hi - lo
	for item:TreeItem in items:
		var raw:Variant = item.get_metadata(col)
		if not (raw is float):
			item.clear_custom_bg_color(col)
			continue
		var n:float = raw
		if not is_finite(n):
			item.clear_custom_bg_color(col)
			continue
		var t:float = (n - lo) / span
		if not lower:
			t = 1.0 - t
		item.set_custom_bg_color(col, _heat(t))


func _heat(t:float) -> Color:
	var u:float = clampf(t, 0.0, 1.0)
	if u < 0.5:
		return HEAT_BEST.lerp(HEAT_MID, u * 2.0)
	return HEAT_MID.lerp(HEAT_WORST, (u - 0.5) * 2.0)
