class_name FrozenEffectComp extends Node

var Owner : Node2D
var CooldownComp : CooldownComponent
var Duration : float = 1500

func _init(duration : float = self.Duration) -> void:
	self.Duration = duration

func _ready() -> void:
	self.CooldownComp = $cool_down_comp
	self.CooldownComp.cooldown_end.connect(self._handle_cooldown_end)
	self.CooldownComp.start(self.Duration)

func _handle_cooldown_end() -> void:
	self.queue_free()

static func get_class_name() -> StringName:
	return "FrozenEffectComponent"
