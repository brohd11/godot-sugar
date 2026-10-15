class_name Sugar

## Convenience helpers that trade a call for brevity. Tagged ones are expanded inline by
## gdscript_optimizer on export, so the cost only exists in unexported code.

## Unoptimized, every argument is evaluated; inlined, it short-circuits like `and`.
#! inline; substitute
static func all(...values:Array) -> bool:
	for value in values:
		if not value:
			return false
	return true

## Unoptimized, every argument is evaluated; inlined, it short-circuits like `or`.
#! inline; substitute
static func any(...values:Array) -> bool:
	for value in values:
		if value:
			return true
	return false

## Sets each key as a property, for optional-arg factories: `return Sugar.set_params(new(), params)`.
## Not inlined: the optimizer doesn't import bodies with loops.
static func set_params(ins:Object, params:Dictionary) -> Object:
	for k:StringName in params.keys():
		ins.set(k, params[k])
	return ins
