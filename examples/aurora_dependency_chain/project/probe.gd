extends SceneTree

func _init():
	var extension = load("res://probe.gdextension")
	if extension == null or not ClassDB.class_exists("AuroraDependencyProbe"):
		push_error("GDExtension or its dependency chain did not load")
		quit(1)
		return
	var probe = ClassDB.instantiate("AuroraDependencyProbe")
	if probe.value() != 42:
		push_error("Wrong result from native dependency chain")
		quit(2)
		return
	print("AURORA_GDEXTENSION_CHAIN_OK")
	quit(0)
