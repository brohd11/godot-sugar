extends RefCounted
## Optimizer input for sugar_test.gd: each call should expand to a bare `and`/`or` chain.

static var events:String = ""

static func probe(label:String, value:bool) -> bool:
	events += label
	return value

static func all_false() -> bool:
	return Sugar.all(probe("a", true), probe("b", false), probe("c", true))

static func any_true() -> bool:
	return Sugar.any(probe("a", false), probe("b", true), probe("c", true))
