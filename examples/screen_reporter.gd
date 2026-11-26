@tool
extends BenchmarkReporter

## Console (editor log) plus structured rows for the on-screen table.
## Human path: table cells. Machine path: [ConsoleReporter] as before.

const _Console = preload("res://addons/enetheru.gdsbench/lib/console_reporter.gd")
const StrUtil = preload("res://addons/enetheru.gdsbench/lib/string_util.gd")

const NBSP:String = "\u00a0"

var console:BenchmarkReporter = _Console.new()
var rows:Array[Row] = []
var extra_keys:PackedStringArray = PackedStringArray()
var extra_lower_better:Dictionary = {}
var name_help:Dictionary = {}
var context_line:String = ""
var notices:PackedStringArray = PackedStringArray()
var errors:PackedStringArray = PackedStringArray()


class Row:
	var name:String = ""
	var seconds:float = 0.0
	var time:String = ""
	var iters:String = ""
	var iters_n:int = 0
	var extras:Dictionary = {}
	var extra_values:Dictionary = {}
	var note:String = ""
	var tooltip:String = ""
	var family:String = ""


func _init() -> void:
	error_sink = _on_error


func _on_error(msg:String) -> void:
	var _n:int = errors.append(msg)
	BenchLib.ReportError(msg)


func ReportContext(context:Context) -> bool:
	var ok:bool = console.ReportContext(context)
	var info:CPUInfo = context.cpu_info
	var parts:PackedStringArray = PackedStringArray()
	if info.num_cpus > 0:
		var _n:int = parts.append("%d CPU%s" % [
				info.num_cpus, "s" if info.num_cpus != 1 else ""])
	var mhz:float = info.cycles_per_second / 1000000.0
	if mhz >= 1.0:
		var _m:int = parts.append("%.0f%sMHz" % [mhz, NBSP])
	context_line = " · ".join(parts)
	if OS.is_debug_build():
		var _d:int = notices.append("Debug build — treat times as relative.")
	return ok


func ReportRuns(report:Array[Run]) -> void:
	console.ReportRuns(report)
	for run:Run in report:
		var row := Row.new()
		row.name = run.benchmark_name()
		row.family = run.run_name.function_name
		row.tooltip = _describe_name(run)
		if run.skipped == Skipped.SkippedWithError:
			row.note = run.skip_message
			row.time = "error"
		elif run.skipped == Skipped.SkippedWithMessage:
			row.note = run.skip_message
			row.time = "skipped"
		else:
			row.seconds = _seconds(run)
			row.iters_n = run.iterations
			row.iters = str(run.iterations)
			for key:String in run.counters.keys():
				var cnt:Counter = run.counters[key]
				row.extras[key] = _format_counter(cnt)
				row.extra_values[key] = cnt.value
				if extra_keys.find(key) < 0:
					var _k:int = extra_keys.append(key)
					extra_lower_better[key] = _guess_lower_better(cnt)
		rows.append(row)


func finish() -> void:
	var unit:TimeUnit = _pick_unit_from_rows()
	var unit_s:String = GetTimeUnitString(unit)
	var mult:float = GetTimeUnitMultiplier(unit)
	for row:Row in rows:
		if not row.time.is_empty():
			continue
		row.time = "%s%s%s" % [_trim_time(row.seconds * mult), NBSP, unit_s]


func _pick_unit_from_rows() -> TimeUnit:
	var worst:float = 0.0
	for row:Row in rows:
		if row.time.is_empty():
			worst = maxf(worst, row.seconds)
	if worst >= 1.0:
		return TimeUnit.kSecond
	if worst >= 0.001:
		return TimeUnit.kMillisecond
	if worst >= 0.000001:
		return TimeUnit.kMicrosecond
	return TimeUnit.kNanosecond


func guess_lower_better(key:String) -> bool:
	if extra_lower_better.has(key):
		return extra_lower_better[key]
	return false


func _describe_name(run:Run) -> String:
	var nm:BenchmarkName = run.run_name
	var lines:PackedStringArray = PackedStringArray()
	var family:String = nm.function_name
	if family.is_empty():
		family = run.benchmark_name()
	var _h:int = lines.append(family)
	var help:Dictionary = {}
	if name_help.has(family):
		help = name_help[family]
	var blurb:String = ""
	var arg_help:Dictionary = {}
	if help.has(&"blurb"):
		blurb = help[&"blurb"]
	if help.has(&"args"):
		arg_help = help[&"args"]
	if not blurb.is_empty():
		var _b:int = lines.append("  %s" % blurb)
	if run.run_type == Run.RunType.RT_Aggregate \
	and not run.aggregate_name.is_empty():
		var _a:int = lines.append(
				"  %s    statistic over repetitions" % run.aggregate_name)
	if not nm.args.is_empty():
		var idx:int = 0
		for tok:String in nm.args.split("/"):
			var _arg:int = lines.append("  %s" % _describe_arg(tok, idx, arg_help))
			idx += 1
	if not nm.min_time.is_empty():
		var _mt:int = lines.append("  %s    minimum seconds per repetition" % \
				nm.min_time)
	if not nm.min_warmup_time.is_empty():
		var _wu:int = lines.append("  %s    warmup discarded before timing" % \
				nm.min_warmup_time)
	if not nm.iterations.is_empty():
		var _it:int = lines.append("  %s    fixed iteration count" % \
				nm.iterations)
	if not nm.repetitions.is_empty():
		var _rp:int = lines.append("  %s    how many times this instance runs" % \
				nm.repetitions)
	if not nm.time_type.is_empty():
		for tok:String in nm.time_type.split("/"):
			var _tt:int = lines.append("  %s    %s" % [tok, _describe_time_type(tok)])
	if not nm.threads.is_empty():
		var _th:int = lines.append("  %s    concurrent threads" % nm.threads)
	if lines.size() == 1:
		var _o:int = lines.append("  (no / variants on this name)")
	return "\n".join(lines)


func _describe_arg(tok:String, idx:int, arg_help:Dictionary) -> String:
	var colon:int = tok.find(":")
	if colon > 0:
		var label:String = tok.substr(0, colon)
		var value:String = tok.substr(colon + 1)
		return "%s = %s    %s" % [label, value, _arg_gloss(arg_help, label, idx)]
	return "%s    %s" % [tok, _arg_gloss(arg_help, str(idx), idx)]


func _arg_gloss(arg_help:Dictionary, key:String, idx:int) -> String:
	if arg_help.has(key):
		var gloss:String = arg_help[key]
		return gloss
	if arg_help.has(str(idx)):
		var by_i:String = arg_help[str(idx)]
		return by_i
	if key.is_valid_int():
		return "unnamed argument %d" % idx
	return "argument"


func _describe_time_type(tok:String) -> String:
	match tok:
		"real_time":
			return "wall clock, not CPU"
		"manual_time":
			return "time from SetIterationTime"
		"process_time":
			return "process CPU across threads"
		_:
			return "timer mode"


func extra_title(key:String) -> String:
	match key:
		"bytes_per_second":
			return "bytes/s"
		"items_per_second":
			return "items/s"
		_:
			return key


func _seconds(run:Run) -> float:
	if run.iterations == 0:
		return run.real_accumulated_time
	return run.real_accumulated_time / float(run.iterations)


func _trim_time(time:float) -> String:
	return _Console.FormatTime(time).strip_edges()


func _guess_lower_better(cnt:Counter) -> bool:
	if (cnt.flags & Counter.Flags.kInvert) != 0:
		return true
	if (cnt.flags & Counter.Flags.kIsRate) != 0:
		return false
	return false


func _format_counter(cnt:Counter) -> String:
	var s:String = StrUtil.HumanReadableNumber(cnt.value, cnt.one_k)
	if (cnt.flags & Counter.Flags.kIsRate) != 0:
		if (cnt.flags & Counter.Flags.kInvert) != 0:
			return "%s%ss" % [s, NBSP]
		return "%s/s" % s
	return s
