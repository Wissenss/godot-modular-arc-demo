extends Node

var player_one : CharacterOne
var player_one_ui : PlayerInfoComp

func _ready() -> void:
	self.player_one_ui = $player1_info
	
	self.player_one = $"../character_one"
	await self.player_one.ready # ugly: the health comp is assign on CharacterOne Ready, so here we wait for that to happend to preven AVs 
	self.player_one.HealthComp.on_health_changed.connect(self._handle_on_player_one_health_changed)
	
	self._update_display_one()

func _handle_on_player_one_health_changed(health : int, old_health : int) -> void:
	self._update_display_one()

func _update_display_one() -> void:
	self.player_one_ui.PlayerName = "Packet Loss Over Wifi"
	self.player_one_ui.Health = self.player_one.HealthComp.get_health()
	self.player_one_ui.Mana = 0 # TODO: handle mana
	
	self.player_one_ui._update()
