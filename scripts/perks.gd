
extends Node

func apply(player, id):
	match id:
		"hp":
			player.max_hp += 25
		"speed":
			player.speed *= 1.2
		"damage":
			player.damage_multiplier *= 1.2
