extern "C" int aurora_leaf_value();
extern "C" int aurora_middle_value() {
	return aurora_leaf_value() + 2;
}
