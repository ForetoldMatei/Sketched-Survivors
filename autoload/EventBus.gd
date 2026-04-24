extends Node

signal xp_collected(amount: int)
signal player_level_up(new_level: int)
signal enemy_died(enemy: Node, killer: Node, death_position: Vector2)
signal player_died()
signal run_paused(paused: bool)
signal run_started()
signal wave_started(wave_index: int)
signal wave_cleared(next_wave_index: int)
signal wave_completed(final_wave_index: int)
