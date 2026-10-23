#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

extern "C" int aurora_middle_value();

class AuroraDependencyProbe : public godot::RefCounted {
	GDCLASS(AuroraDependencyProbe, godot::RefCounted);

protected:
	static void _bind_methods() {
		godot::ClassDB::bind_method(godot::D_METHOD("value"), &AuroraDependencyProbe::value);
	}

public:
	int value() const { return aurora_middle_value(); }
};

static void initialize(godot::ModuleInitializationLevel p_level) {
	if (p_level == godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		GDREGISTER_CLASS(AuroraDependencyProbe);
	}
}

static void terminate(godot::ModuleInitializationLevel p_level) {}

extern "C" GDExtensionBool GDE_EXPORT aurora_probe_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init(p_get_proc_address, p_library, r_initialization);
	init.register_initializer(initialize);
	init.register_terminator(terminate);
	init.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);
	return init.init();
}
