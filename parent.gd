extends Node2D

#im not sure if all of this need to be preloaded actually
@onready var boss_health_bar = $"Gameboard/boss health bar"
@onready var senior_player_healthbars = $"Gameboard/Senior Player Healthbars".get_children()
@onready var junior_player_healthbars = $"Gameboard/Junior Player Healthbars".get_children()
@onready var countdown_timer = $"Question Display"/Control
@onready var operator = $Operator2/Operator
@onready var text_label = $"Question Display/Question Label"
@onready var glitch_effect = $"Camera2D/Glitch Effect"
#these definitely don't need to be preloaded
@onready var quesb = $"Question Display"
@onready var opp = $Operator2
@onready var psgm = $PseudoGameboard
@onready var game = $Gameboard

var ending = preload("res://videos/ending.ogv")
var good_ending = preload("res://videos/good ending.ogv")
var bad_ending = preload("res://videos/bad ending.ogv")
var no_questions = preload("res://videos/no questions left.ogv")
var tie = preload("res://videos/tie.ogv")

var sr_questions = [] #holds all the questions, gets them from the operator
var sr_points = [] #holds all the corresponding points
var jr_questions = []
var jr_points = []
var sr_teams = ["", "", "", ""] #holds senior teams
var jr_teams = ["", "", "", ""] #holds juniour teams
var images_filepath = []

var qnum := 0
var question_points := 0
var questions_left = 40
var tie_questions_count := 2
var current_team := 0
var previous_team := 0
var sr_teams_left := 4
var jr_teams_left := 4
var is_senior_round := true
var team_skipped := false
var is_input_finished := false
var is_in_tie_round := false
var is_boss_dead := false

func _ready() -> void:
	countdown_timer.connect("correct_answer", on_correct_answer)
	countdown_timer.connect("incorrect_answer", on_incorrect_answer)
	countdown_timer.connect("ready_for_question", set_question)
	operator.connect("input_finished", on_input_finished)
	boss_health_bar.connect("boss_died", on_boss_death)
	
	for child in senior_player_healthbars:
		child.connect("player_died", on_player_death)
	for child in junior_player_healthbars:
		child.connect("player_died", on_player_death) 
	
	#connects the manager to all the necessary signals in the code
	#this prevents code entangling, the manager simply gets the values necsesary without the child nodes
	#having to give them to it
	randomize()
	#randomises godot's built in random function so we get random values each time

func on_input_finished(_sr_questions, _sr_points, _jr_questions, _jr_points, _sr_teams, _jr_teams): #this is called when the operator finishes all the inputs
	sr_questions = _sr_questions
	sr_points = _sr_points
	jr_questions = _jr_questions
	jr_points = _jr_points
	sr_teams = _sr_teams
	jr_teams = _jr_teams
	#it gets the necessary values inputted from the operator and sets them all
	
	for i in range(len(sr_questions) + len(jr_questions)):
		images_filepath.append(i + 1)
	
	psgm.visible = true 
	#makes the 'fake' game board visible
	opp.visible = false
	#and makes the operator invisible
	
	is_input_finished = true

func set_question(): #sets the question when told to do so after the button is pressed
	#necessary because the button is connected to the timer and not the manager 
	if sr_questions != [] and jr_questions != [] and questions_left > 0: #checks if there are questions left or if we exceeded max questions
		if is_senior_round:
			if sr_teams_left <= 1 and !is_in_tie_round:
				is_senior_round = false
				set_question()#if senior category is over shifts to the junior automatically
				update_game_board()
				return
			
			if team_skipped and !is_in_tie_round: #if a team was previously skipped due to being dead
				current_team = previous_team #we go back to the previous index to prevent
				team_skipped = false #a team being skipped here
			
			if senior_player_healthbars[current_team].current_health <= 0: #if the current team is dead
				previous_team = current_team #we remember what team we were in for the juniour category
				team_skipped = true #remember it was skipped
				current_team += 1 #move onto to the next team
				if current_team >= 4:
					current_team = 0
				set_question()
				update_game_board()
				return
			
			qnum = randi_range(0, len(sr_questions) - 1) #chooses a random question
			
			text_label.text = sr_questions[qnum].split("|", true, 0)[0] #displays the question
			question_points = sr_points[qnum] #the timer node requires the questions points so it can send it back to the manager
			countdown_timer.answer = sr_questions[qnum].split("|", true, 0)[1]
			
			$"Question Display/Team Name + Score".text = "Team: " + sr_teams[current_team] + "\n" + "Points: " + str(question_points)
			#displays current team and quesstion
			display_image()
			
			sr_questions.remove_at(qnum)
			sr_points.remove_at(qnum)
			#removes the question from the array as it was already asked
		else:
			if jr_teams_left <= 1 and !is_in_tie_round:
				is_senior_round = true
				set_question()#same as above but vice versa
				update_game_board()
				return
			
			if team_skipped and !is_in_tie_round:
				current_team = previous_team
				team_skipped = false
			
			if junior_player_healthbars[current_team].current_health <= 0: #in case current team is dead
				previous_team = current_team
				team_skipped = true
				current_team += 1 #skips the team
				if current_team >= 4:
					current_team = 0
				set_question()
				update_game_board()
				return
			
			qnum = randi_range(0, len(jr_questions) - 1)
			
			text_label.text = jr_questions[qnum].split("|", true, 0)[0]
			question_points = jr_points[qnum]
			countdown_timer.answer = jr_questions[qnum].split("|", true, 0)[1]
			
			$"Question Display/Team Name + Score".text = "Team: " + jr_teams[current_team] + "\n" + "Points: " + str(question_points)
			
			display_image()
			
			jr_questions.remove_at(qnum)
			jr_points.remove_at(qnum)
		
		countdown_timer.timer_label.text = "0"
		
		questions_left -= 1
		#decrements current question by one
	else:
		if questions_left <= 0 and !is_in_tie_round:
			$"GO Screen/VideoStreamPlayer".stream = no_questions
			$"GO Screen/VideoStreamPlayer".play()
			await $"GO Screen/VideoStreamPlayer".finished
		is_tie()

func boss_heals(amount): #in case of incorrect question
	boss_health_bar.increase_health(amount/2)
	if is_senior_round:
		senior_player_healthbars[current_team].decrease_health(amount/2)
	else:
		junior_player_healthbars[current_team].decrease_health(amount/2)

func player_heals(amount): #in case of correct question
	if is_senior_round:
		senior_player_healthbars[current_team].increase_health(amount)
	else:
		junior_player_healthbars[current_team].increase_health(amount)
	boss_health_bar.decrease_health(amount)

func player_steals(amount, id, success): #in case of an incorrect question, but stolen
	if is_senior_round:
		senior_player_healthbars[current_team].decrease_health(amount/2)
		if success: #if successfully stolen
			senior_player_healthbars[id].increase_health(amount/2)
		else: #if unsucceessfully stolen, damages the team that tried to steal
			senior_player_healthbars[id].decrease_health(amount/2)
			boss_health_bar.increase_health(amount/2)
	else:
		junior_player_healthbars[current_team].decrease_health(amount/2)
		if success:
			junior_player_healthbars[id].increase_health(amount/2)
		else:
			junior_player_healthbars[id].decrease_health(amount/2)
			boss_health_bar.increase_health(amount/2)

func on_correct_answer(): #called when the timer scene tells the manager the question was correct
	#im not entirely sure why the timer scene handles inputs actually, maybe because the timer is there and so is the button
	#maybe it should be called the "interactbles" scene?
	print("answer was correct")
	
	text_label.text = "Correct Answer!!"
	await get_tree().create_timer(1.2).timeout
	
	countdown_timer.question_button.disabled = false #reenables the button for the next input
	
	quesb.visible = false
	game.visible = true
	
	game.animations("player attack", current_team, is_senior_round, 0, null)
	player_heals(question_points) #update the necessary things
	
	if sr_teams_left > 1 and jr_teams_left > 1:
		is_senior_round = !is_senior_round #toggles between rounds
	
	await get_tree().create_timer(2).timeout
	update_game_board()
	update_current_team()

func on_incorrect_answer(id, success): #same as above, just in case of an incorrect answer (or timer ran out)
	
	text_label.text = "Correct answer: " + countdown_timer.answer
	await get_tree().create_timer(3).timeout
	
	print("answer was incorrect")
	countdown_timer.question_button.disabled = false
	
	quesb.visible = false
	game.visible = true #updates scenee
	
	if id == -1:
		game.animations("boss attack", current_team, is_senior_round, id, null)
		boss_heals(question_points)
	else:
		game.animations("boss attack", current_team, is_senior_round, id - 1, success)
		player_steals(question_points, id - 1, success)
	#to differentiate if stolen or not
	
	if sr_teams_left > 1 and jr_teams_left > 1:
		is_senior_round = !is_senior_round #toggles between rounds
	
	await get_tree().create_timer(3).timeout
	update_game_board()
	update_current_team()

func _input(event: InputEvent) -> void: #according to the game specifications, when enter is pressed the game actually starts
	if event.is_action_pressed("enter"):
		if psgm.visible:
			glitch_effect.visible = true
			psgm.get_child(0).visible = false
			#$PseudoGameboard/VideoStreamPlayer.play()
			#await $PseudoGameboard/VideoStreamPlayer.finished
			psgm.visible = false
			game.visible = true
			$"Gameboard/Senior teams".visible = true
			$"Gameboard/Senior Player Healthbars".visible = true
			#sets all the relevant visibilities
			for i in 8: #displays all the reelevant team names here
				if i < 4:
					senior_player_healthbars[i].get_child(1).text = sr_teams[i]
				else:
					junior_player_healthbars[i - 4].get_child(1).text = jr_teams[i - 4]
			await get_tree().create_timer(.5).timeout
			glitch_effect.visible = false
		else:
			if is_input_finished: #for switching to the question scene by pressing 'enter'
				game.visible = false
				quesb.visible = true
				countdown_timer.timer_label.text = "0"
				$"Question Display/Question Label".text = ""
				$"Question Display/Team Name + Score".text = ""
				$"Question Display/Question Image".texture = null
				if !is_in_tie_round:
					print_health()

func on_boss_death():
	is_boss_dead = true
	game.animations("boss death", 0, false, 0, null)
	await get_tree().create_timer(4).timeout
	$"GO Screen/VideoStreamPlayer".stream = good_ending
	$"GO Screen/VideoStreamPlayer".visible = true
	$"GO Screen/VideoStreamPlayer".play()
	await  $"GO Screen/VideoStreamPlayer".finished
	$"GO Screen/VideoStreamPlayer".visible = false
	is_tie() #if boss dies game should be over

func on_player_death(n : int): #to handle player deaths
	if is_senior_round:
		print(sr_teams[n] + " has died!")
		sr_teams_left -= 1
		
		$"Gameboard/Senior teams".get_child(n).visible = false
	else:
		print(jr_teams[n] + " has died!")
		jr_teams_left -= 1
		
		$"Gameboard/Junior teams".get_child(n).visible = false
		
	if sr_teams_left <= 1 and jr_teams_left <= 1:
		await get_tree().create_timer(6).timeout
		$"GO Screen/VideoStreamPlayer".stream = load("res://6804117-uhd_4096_2160_25fps.ogv")
		$"GO Screen/VideoStreamPlayer".play()
		await $"GO Screen/VideoStreamPlayer".finished
		game_over(sr_teams, jr_teams) #if enough teams aren't left game is over

func game_over(_sr_teams, _jr_teams):
	print("game over") #rudimentary game over function, simply loads the game over screen
	
	$Gameboard/VideoStreamPlayer.stream = ending if is_boss_dead else bad_ending
	$Gameboard/VideoStreamPlayer.play()
	await $Gameboard/VideoStreamPlayer.finished
	
	glitch_effect.visible = true
	for child in get_children():
		if child != glitch_effect:
			child.visible = false #sets everything else invisible
	$"GO Screen".visible = true 
	await get_tree().create_timer(.4).timeout
	glitch_effect.visible = false
	
	for i in range(4):
		$"GO Screen/Game over screen/Label2".get_child(i).text = _sr_teams[i] + ": " + str(senior_player_healthbars[i].current_health)
		$"GO Screen/Game over screen/Label3".get_child(i).text = _jr_teams[i] + ": " + str(junior_player_healthbars[i].current_health)
		#displays the teams and scores 

func display_image():
	var filepath : String
	if is_senior_round:
		filepath = "res://Builds/Images/Senior/" + str(images_filepath[qnum]) + ".png"
		if !ResourceLoader.exists(filepath):
			print("Could not load image ", filepath, " as there was an error in loading")
			return
			
		images_filepath.remove_at(qnum)
	else:
		filepath = "res://Builds/Images/Junior/" + str(images_filepath[qnum]) + ".png"
		if !ResourceLoader.exists(filepath):
			print("Could not load image ", filepath, " as there was an error in loading")
			return
		
		images_filepath.remove_at(qnum)
	
	var t = ImageTexture.new()
	t = ResourceLoader.load(filepath)
	$"Question Display/Question Image".texture = t
#function for displaying images, nto every quesstion has an image so if the image's filepath does not exist it can
#account for that and not throw an error
func is_tie():
	$"Gameboard/boss health bar".visible = false
	$Gameboard/Monsters.visible = false
	
	var _sr_teams = sr_teams.duplicate()
	var _jr_teams = jr_teams.duplicate()
	
	var sr_point_total = []
	var jr_point_total = []
	for i in range(4):
		sr_point_total.append(senior_player_healthbars[i].current_health)
		jr_point_total.append(junior_player_healthbars[i].current_health)
	sr_point_total.sort()
	jr_point_total.sort()
	print(sr_point_total, jr_point_total)
	
	if sr_point_total[3] == sr_point_total[2]:
		is_in_tie_round = true
		
		$Gameboard/VideoStreamPlayer.stream = tie
		$Gameboard/VideoStreamPlayer.play()
		await $Gameboard/VideoStreamPlayer.finished
		
		sr_teams_left = 0
		questions_left = tie_questions_count
		is_senior_round = true
		current_team = 0
		
		for i in range(4):
			if senior_player_healthbars[i].current_health != sr_point_total[3]:
				senior_player_healthbars[i].decrease_health(9999)
			else:
				sr_teams_left += 1
		
		update_game_board()
		set_question()
	elif jr_point_total[3] == jr_point_total[2]:
		is_in_tie_round = true
		
		$Gameboard/VideoStreamPlayer.stream = tie
		$Gameboard/VideoStreamPlayer.play()
		await $Gameboard/VideoStreamPlayer.finished
		
		jr_teams_left = 0
		questions_left = tie_questions_count
		is_senior_round = false
		current_team = 0
		
		for i in range(4):
			if junior_player_healthbars[i].current_health != jr_point_total[3]:
				junior_player_healthbars[i].decrease_health(9999)
			else:
				jr_teams_left += 1
		
		update_game_board()
		set_question()
	else:
		game_over(_sr_teams, _jr_teams)
#checks if tie, first for seniors, then for juniors and then ends the game
func update_current_team():
	if is_senior_round or is_in_tie_round:
		current_team += 1
		if current_team >= 4:
			current_team = 0
	#updates current round every senior round, this is called only after the last round has fully finished

func update_game_board(): #updates the textures and stuff
	glitch_effect.visible = true
	if is_senior_round:
		$"Gameboard/Senior teams".visible = true
		$"Gameboard/Senior Player Healthbars".visible = true
		$"Gameboard/Junior teams".visible = false
		$"Gameboard/Junior Player Healthbars".visible = false
	else:
		$"Gameboard/Junior teams".visible = true
		$"Gameboard/Junior Player Healthbars".visible = true
		$"Gameboard/Senior teams".visible = false
		$"Gameboard/Senior Player Healthbars".visible = false
	await get_tree().create_timer(.15).timeout
	glitch_effect.visible = false

func print_health(): #for debugging purposes, prints a bunch of stuff
	for i in range(4):
		print(sr_teams[i] + " " + str(senior_player_healthbars[i].current_health))
		print(jr_teams[i] + " " + str(junior_player_healthbars[i].current_health))
	print("boss health: ", boss_health_bar.current_health)
	print("current team: " + str(current_team + 1))
	print("senior round: " + str(is_senior_round))
	print("senior teams left ", sr_teams_left)
	print("junior teams left ", jr_teams_left)
	print("questions left: " + str(questions_left))
