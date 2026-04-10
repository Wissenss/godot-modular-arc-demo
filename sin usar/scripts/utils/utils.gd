class_name Utils extends Node

static func HasComponent(parent : Node, comp_class_name : StringName) -> bool:
	for child in parent.get_children():
		if child.has_method("get_class_name") == false:
			continue
		
		if child.get_class_name() == comp_class_name:
			return true
		
	return false
