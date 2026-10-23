extends Node3D

var cube: MeshInstance3D
var counter: Label
var taps := 0
var extension: GDExtension

func _ready():
	extension = load("res://probe.gdextension")
	if extension == null or not ClassDB.class_exists("AuroraDependencyProbe"):
		push_error("Native extension is unavailable")
		get_tree().quit(1)
		return
	var probe = ClassDB.instantiate("AuroraDependencyProbe")
	if probe.value() != 42:
		get_tree().quit(2)
		return
	print("AURORA_GDEXTENSION_CHAIN_OK")
	cube = MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("46b8da")
	material.metallic = 0.25
	cube.material_override = material
	add_child(cube)
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1, 4)
	add_child(camera)
	camera.look_at(Vector3.ZERO)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("102130")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.4
	add_child(environment)
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(48, 64)
	panel.add_theme_constant_override("separation", 24)
	layer.add_child(panel)
	var title := Label.new()
	title.text = "Godot 4.7.2 / Aurora OS"
	title.add_theme_font_size_override("font_size", 36)
	panel.add_child(title)
	var status := Label.new()
	status.text = "GLES 3 • native dependency chain = 42"
	status.add_theme_font_size_override("font_size", 24)
	panel.add_child(status)
	counter = Label.new()
	counter.text = "Touches: 0"
	counter.add_theme_font_size_override("font_size", 28)
	panel.add_child(counter)
	var button := Button.new()
	button.text = "Test touch"
	button.custom_minimum_size = Vector2(320, 96)
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(func():
		taps += 1
		counter.text = "Touches: %d" % taps
		print("AURORA_TOUCH_OK:", taps)
	)
	panel.add_child(button)

func _process(delta):
	if cube:
		cube.rotate_y(delta * 0.7)
		cube.rotate_x(delta * 0.3)
