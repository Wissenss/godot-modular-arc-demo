class_name HealthComponent extends Node

# resp: track life value

var _health := 0
var _max_health := 100

signal on_health_changed(health: int, old_health: int)
signal on_died()

func set_health(value: int) -> void:
	var old_value = self._health
	
	self._health = min(value, self._max_health)
	
	# prevent echo event emissions if health value did not changed
	if old_value == self._health:
		return
	
	on_health_changed.emit(self._health, old_value)
	
	if self._health <= 0:
		on_died.emit()

func take_damage(damage : int) -> void:
	self.set_health(self._health - damage)

func get_health() -> int:
	return self._health

func set_max_health(value: int) -> void:
	self._max_health = value
	self.set_health(self._health)

func get_max_health() -> int:
	return self._max_health
