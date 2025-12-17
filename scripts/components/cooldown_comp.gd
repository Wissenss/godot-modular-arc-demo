class_name CooldownComponent extends Node

var _Timer : Timer
var Timespan : float = INF # cooldown timespan in miliseconds, because why the fuck godot does it with seconds?!?

signal cooldown_start()
signal cooldown_end()

func _ready() -> void:
	self._Timer = $timer
	self._Timer.timeout.connect(self._handle_timeout)

# TODO: proper getter/setter
func _set_timespan(timespan: float) -> void:
	self.Timespan = timespan
	self._Timer.wait_time = self.Timespan / 1000

func start(timespan : float = self.Timespan):
	self._set_timespan(timespan)
	self._Timer.start()
	
	self.cooldown_start.emit()

func _handle_timeout() -> void:
	self.cooldown_end.emit()
