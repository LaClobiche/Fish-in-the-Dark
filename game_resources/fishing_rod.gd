class_name FishingRod

extends Resource


var hp_max: int = 100
var hp: int = 100:
	set(value):
		if value <= 0:
			hp = 0
			Signals.game_over_requested.emit()
		elif value > hp_max:
			hp = hp_max
		else:
			hp = value


func take_damage(damage: int):
	Sound.play_se(Sound.effects["rod_damage_crack"])
	hp -= damage
	print("damage taken")
