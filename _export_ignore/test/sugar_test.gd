extends RefCounted
## Sugar's behavior unoptimized, plus a guard that all/any stay recognized by the optimizer's
## variadic reduction, since that expansion is the reason they exist.

# Loaded, not preloaded: the optimizer is optional, so its absence fails this test, not the package.
const OPTIMIZER = "res://addons/_lib/gdscript_optimizer/src/optimizer.gd"
const SUGAR = "res://addons/_lib/sugar/src/sugar.gd"
const CALLER = "res://addons/_lib/sugar/_export_ignore/test/fixtures/caller.gd"

class Params:
	var a:int = 1
	var b:String = "x"

static func run_tests() -> Dictionary:
	var failures:Array = []
	_test_plain(failures)
	_test_inlined(failures)
	return {"result": failures.size(), "output": ["sugar: %d failures" % failures.size()] + failures}

static func _test_plain(failures:Array) -> void:
	if not Sugar.all() or Sugar.all(true, 0) or not Sugar.all(true, 1, "s"):
		failures.append("all() wrong")
	if Sugar.any() or not Sugar.any(false, 1) or Sugar.any(false, 0, ""):
		failures.append("any() wrong")
	var ins := Sugar.set_params(Params.new(), {"b": "y"}) as Params
	if ins.a != 1 or ins.b != "y":
		failures.append("set_params() wrong: a=%s b=%s" % [ins.a, ins.b])

static func _test_inlined(failures:Array) -> void:
	if not ResourceLoader.exists(OPTIMIZER):
		failures.append("gdscript_optimizer not found at " + OPTIMIZER)
		return
	var Optimizer = load(OPTIMIZER)
	var context = Optimizer.Context.new()
	context.set_global_classes({"Sugar": SUGAR})
	var optimizer = Optimizer.new()
	var prepared:Dictionary = optimizer.prepare({CALLER: CALLER, SUGAR: SUGAR}, context, [Optimizer.InlinePass])
	if not prepared.errors.is_empty():
		failures.append("prepare errors: " + str(prepared.errors))
		return
	var result:Dictionary = optimizer.apply(CALLER, Array(FileAccess.get_file_as_string(CALLER).split("\n")))
	var text:String = "\n".join(result.lines)
	if text.contains("Sugar.all(") or text.contains("Sugar.any("):
		failures.append("call not inlined: " + str(result.get("warnings", [])))
		return
	var script := GDScript.new()
	script.source_code = text
	if script.reload() != OK:
		failures.append("inlined caller failed to compile:\n" + text)
		return
	# Short-circuit proves it became `and`/`or` rather than a captured call.
	for entry:Array in [["all_false", false, "ab"], ["any_true", true, "ab"]]:
		script.events = ""
		var actual:Variant = script.call(entry[0])
		if actual != entry[1] or script.events != entry[2]:
			failures.append("%s: result=%s events=%s expected=%s" % [entry[0], actual, script.events, entry])
