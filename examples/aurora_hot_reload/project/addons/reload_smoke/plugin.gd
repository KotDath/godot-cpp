@tool
extends EditorPlugin

var extension: GDExtension
var probe: RefCounted
var original_id := 0
var sequence := 0
var elapsed := 0.0

func _enter_tree() -> void:
	call_deferred("_start")

func _start() -> void:
	extension = load("res://probe.gdextension")
	if not extension or not ClassDB.class_exists("AuroraReloadProbe"):
		_write({"ready": false, "error": "Native class unavailable"})
		return
	probe = ClassDB.instantiate("AuroraReloadProbe")
	probe.set("state", 73)
	original_id = probe.get_instance_id()
	_write({"ready": true, "sequence": 0, "revision": probe.call("revision"), "state": probe.get("state"), "pid": OS.get_process_id()})

func _process(delta: float) -> void:
	if not probe:
		return
	elapsed += delta
	if elapsed < 0.2:
		return
	elapsed = 0.0
	if not FileAccess.file_exists("res://.aurora-reload-command.json"):
		return
	var command = JSON.parse_string(FileAccess.get_file_as_string("res://.aurora-reload-command.json"))
	if not command is Dictionary or int(command.get("sequence", 0)) <= sequence:
		return
	sequence = int(command["sequence"])
	if command.get("quit", false):
		get_tree().quit()
		return
	var result := GDExtensionManager.reload_extension("res://probe.gdextension")
	_write({"ready": true, "sequence": sequence, "reload_status": result, "revision": probe.call("revision"), "state": probe.get("state"), "same_instance": probe.get_instance_id() == original_id, "pid": OS.get_process_id()})

func _write(data: Dictionary) -> void:
	var file := FileAccess.open("res://.aurora-reload-result.json.tmp", FileAccess.WRITE)
	if not file:
		push_error("Cannot write reload evidence")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	DirAccess.rename_absolute("res://.aurora-reload-result.json.tmp", "res://.aurora-reload-result.json")
	print("AURORA_HOT_RELOAD ", JSON.stringify(data))
