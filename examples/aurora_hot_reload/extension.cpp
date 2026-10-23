#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/godot.hpp>

class AuroraReloadProbe : public godot::RefCounted {
	GDCLASS(AuroraReloadProbe, godot::RefCounted);
	int state = 0;

protected:
	static void _bind_methods() {
		godot::ClassDB::bind_method(godot::D_METHOD("revision"), &AuroraReloadProbe::revision);
		godot::ClassDB::bind_method(godot::D_METHOD("get_state"), &AuroraReloadProbe::get_state);
		godot::ClassDB::bind_method(godot::D_METHOD("set_state", "value"), &AuroraReloadProbe::set_state);
		ADD_PROPERTY(godot::PropertyInfo(godot::Variant::INT, "state"), "set_state", "get_state");
	}

public:
	int revision() const { return AURORA_RELOAD_REVISION; }
	int get_state() const { return state; }
	void set_state(int p_value) { state = p_value; }
};

static void initialize(godot::ModuleInitializationLevel p_level) {
	if (p_level == godot::MODULE_INITIALIZATION_LEVEL_SCENE) {
		GDREGISTER_CLASS(AuroraReloadProbe);
	}
}

static void terminate(godot::ModuleInitializationLevel p_level) {}

extern "C" GDExtensionBool GDE_EXPORT aurora_reload_init(
		GDExtensionInterfaceGetProcAddress p_get_proc_address,
		GDExtensionClassLibraryPtr p_library,
		GDExtensionInitialization *r_initialization) {
	godot::GDExtensionBinding::InitObject init(p_get_proc_address, p_library, r_initialization);
	init.register_initializer(initialize);
	init.register_terminator(terminate);
	init.set_minimum_library_initialization_level(godot::MODULE_INITIALIZATION_LEVEL_SCENE);
	return init.init();
}
