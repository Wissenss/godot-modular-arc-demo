class_name PlayerInfoComp extends Node

# Responsabilidad: esta clase se encarga de mostrar la información del jugador a la pantalla

var PlayerName := ""
var Health := 0
var Mana := 0

var _text_label : Label

func _ready() -> void:
	self._text_label = $text

func _update() -> void:
	var text = ""
	
	text += "\nName: %s" % self.PlayerName
	text += "\nHealth: %d" % self.Health
	text += "\nMana: %d" % self.Mana
	
	self._text_label.text = text
