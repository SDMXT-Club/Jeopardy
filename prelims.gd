extends Node2D

@onready var name_labels := $"Gameboard/Team Score/Name Labels".get_children()
@onready var score_labels := $"Gameboard/Team Score/Score Labels".get_children()
@onready var buttons := $Gameboard/Buttons.get_children()
@onready var text_label := $"Question Display/Question Label"
@onready var countdown_timer := $"Question Display/Control"
@onready var transition := $Transition2/Transition/AnimationPlayer

@onready var game = $Gameboard
@onready var quesb = $"Question Display"
@onready var opp = $"Operator Container/Operator"

var questions := []
var points := []
var teams := ["", "", "", ""]
var team_points := [0, 0, 0, 0]
var images_filepath := ""
var images_left := []
var teams_active := [true, true, true, true]

var question_points := 0
var questions_left := 20
var tie_questions := 5
var current_question := 0
var current_team := 0
var is_in_tie_round := false
var is_senior_round := false

var max_teams = 4

func _ready() -> void:
	opp.connect("input_finished", on_input_finished)
	countdown_timer.connect("correct_answer", on_correct_answer)
	countdown_timer.connect("incorrect_answer", on_incorrect_answer)
	countdown_timer.connect("ready_for_question", set_question)

func on_input_finished(_teams, _questions, _points, _images_filepath, _is_senior_round):
	teams = _teams
	questions = _questions
	points = _points
	images_filepath = _images_filepath
	is_senior_round = _is_senior_round
	
	for i in range(len(questions)):
		images_left.append(i)
	
	for child in buttons:
		child.pressed.connect(display_question.bind(child))
		child.text = "Question " + str(child.get_index() + 1) 
	
	if is_senior_round:
		$"Gameboard/Gameboard Texture/Senior Categories".visible = true
	else:
		$"Gameboard/Gameboard Texture/Junior Categories".visible = true
	
	for i in range(max_teams):
		name_labels[i].text = teams[i] + ":"
		score_labels[i].text = "0000"
	
	transition.play("Transition")
	await transition.animation_finished
	opp.visible = false
	game.visible = true
	transition.play_backwards("Transition")

func display_question(button):
	current_question = button.get_index()
	$"Question Display/Question Image".texture = null
	button.disabled = true
	transition.play("Transition")
	await transition.animation_finished
	game.visible = false
	quesb.visible = true
	transition.play_backwards("Transition")

func set_question():
	if questions != [] and questions_left > 0:
		text_label.text = questions[current_question].split("|", true, 0)[0]
		question_points = points[current_question]
		$"Question Display/Team Name + Score".text = "Team: " + teams[current_team] + "\n" + "Points: " + str(question_points)
		display_image()
		countdown_timer.answer = questions[current_question].split("|", true, 0)[1]

func on_correct_answer(): 
	print("answer was correct")
	
	text_label.text = "Correct Answer!!"
	await get_tree().create_timer(1.2).timeout
	
	countdown_timer.question_button.disabled = false
	
	transition.play("Transition")
	await transition.animation_finished
	quesb.visible = false
	game.visible = true
	transition.play_backwards("Transition")
	
	team_points[current_team] += question_points
	score_labels[current_team].text = str(team_points[current_team])
	
	update_current_team()
	
	questions_left -= 1
	if questions_left <= 0:
		is_tie()
	countdown_timer.timer_label.text = "0"

func on_incorrect_answer(id, success):
	text_label.text = "Incorrect Answer!!"
	await get_tree().create_timer(1.2).timeout
	
	text_label.text = "Correct answer: " + countdown_timer.answer if !success else "Correct Answer!!"
	await get_tree().create_timer(3).timeout
	
	countdown_timer.question_button.disabled = false
	
	transition.play("Transition")
	await transition.animation_finished
	quesb.visible = false
	game.visible = true
	transition.play_backwards("Transition")
	
	team_points[current_team] -= question_points / 2
	score_labels[current_team].text = str(team_points[current_team])
	
	if id != -1:
		if success:
			team_points[id - 1] += question_points / 2
		else:
			team_points[id - 1] -= question_points /2
		score_labels[id - 1].text = str(team_points[id - 1])
	
	update_current_team()
	
	questions_left -= 1
	if questions_left <= 0:
		is_tie()
	countdown_timer.timer_label.text = "0"

func is_tie():
	team_points.sort()
	if team_points[3] == team_points[2]:
		print("is tie", team_points)
		is_in_tie_round = true
		current_team = 0
		questions_left = tie_questions
		for i in range(max_teams):
			if team_points[i] != team_points[3]:
				teams_active[i] = false
		update_current_team()
	else:
		print("game over")
		game_over()

func update_current_team():
	current_team += 1
	if current_team >= max_teams:
		current_team = 0
	if teams_active[current_team] == false:
		current_team += 1
		if current_team > max_teams:
			current_team = 0
	
	text_label.text = ""

func game_over():
	for child in get_children():
		child.visible = false
	
	$"Game over screen".get_node("Label3").visible = false
	$"Game over screen/Label2".text = "Rankings:"
	for child in $"Game over screen/Label2".get_children():
		child.text = str(team_points[3 - child.get_index()])
	$"Game over screen".visible = true

func display_image():
	var filepath = images_filepath + str((current_question + 1) + 25 * (opp.round_no - 1)) + ".png"
	
	if !ResourceLoader.exists(filepath):
		print("Could not load image ", filepath, " as there was an error in loading")
		return
	else:
		var t = ImageTexture.new()
		t = ResourceLoader.load(filepath)
		$"Question Display/Question Image".texture = t
