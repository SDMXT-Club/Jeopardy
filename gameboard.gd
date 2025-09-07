extends Control

func animations(anim_name : String, player_id : int, is_senior_round : bool, s_player_id : int, steal_success):
	var tween = get_tree().create_tween()
	
	if anim_name == "boss attack":
		tween.tween_property($Monsters, "position", Vector2($Monsters.position.x - 50, $Monsters.position.y), .15).set_trans(Tween.TRANS_LINEAR)
		tween.tween_property($Monsters, "position", Vector2(550, -213), .25).set_trans(Tween.TRANS_CUBIC)
		
		await get_tree().create_timer(.08)
		
		if is_senior_round:
			tween.tween_property($"Senior teams".get_child(player_id), "modulate", Color.TRANSPARENT, .08)
			tween.tween_property($"Senior teams".get_child(player_id), "modulate", Color.WHITE, .08)
		else:
			tween.tween_property($"Junior teams".get_child(player_id), "modulate", Color.TRANSPARENT, .08)
			tween.tween_property($"Junior teams".get_child(player_id), "modulate", Color.WHITE, .08)
		
		if !steal_success and steal_success != null:
			if s_player_id > 0:
				if is_senior_round:
					tween.tween_property($"Senior teams".get_child(s_player_id), "modulate", Color.TRANSPARENT, .08)
					tween.tween_property($"Senior teams".get_child(s_player_id), "modulate", Color.WHITE, .08)
				else:
					tween.tween_property($"Junior teams".get_child(s_player_id), "modulate", Color.TRANSPARENT, .08)
					tween.tween_property($"Junior teams".get_child(s_player_id), "modulate", Color.WHITE, .08)
		elif steal_success and steal_success != null:
			if s_player_id > 0:
				if is_senior_round:
					tween.tween_property($"Senior teams".get_child(s_player_id), "modulate", Color.GREEN, .08)
					tween.tween_property($"Senior teams".get_child(s_player_id), "modulate", Color.WHITE, .08)
				else:
					tween.tween_property($"Junior teams".get_child(s_player_id), "modulate", Color.GREEN, .08)
					tween.tween_property($"Junior teams".get_child(s_player_id), "modulate", Color.WHITE, .08)
		
	elif anim_name == "player attack":
		if is_senior_round:
			var player_pos = $"Senior teams".get_child(player_id).position
			tween.tween_property($"Senior teams".get_child(player_id), "position", Vector2(player_pos.x - 25, player_pos.y), .15).set_trans(Tween.TRANS_LINEAR)
			tween.tween_property($"Senior teams".get_child(player_id), "position", Vector2(player_pos.x, player_pos.y), .15).set_trans(Tween.TRANS_CUBIC)
		else:
			var player_pos = $"Junior teams".get_child(player_id).position
			tween.tween_property($"Junior teams".get_child(player_id), "position", Vector2(player_pos.x - 25, player_pos.y), .15).set_trans(Tween.TRANS_LINEAR)
			tween.tween_property($"Junior teams".get_child(player_id), "position", Vector2(player_pos.x, player_pos.y), .15).set_trans(Tween.TRANS_CUBIC)
		
		await get_tree().create_timer(.08)
		
		tween.tween_property($Monsters, "modulate", Color.FIREBRICK, .1)
		tween.tween_property($Monsters, "modulate", Color.WHITE, .1)
	
	elif anim_name == "boss death":
		tween.tween_property($Monsters, "modulate", Color.ORANGE_RED, 0.5)
		tween.tween_property($Monsters, "modulate", Color.ORANGE_RED, 0.3)
		tween.tween_property($Monsters, "modulate", Color.ORANGE_RED, 0.2)
		await tween.finished
		$Explosion.play("default")
		$Monsters.visible = false
