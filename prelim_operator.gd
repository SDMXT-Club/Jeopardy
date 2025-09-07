extends Control

signal input_finished(teams, questions, points, images_filepath, is_senior_round)

var teams := ["", "", "", ""]
var questions := []
var points := []
var round_no := 1

var is_senior_round := false
var is_team_input_finished := false

@export var question_filepath := "res://Builds/Prelim/"
@export var images_filepath := "res://Builds/Prelim/"

@onready var labels := $Labels.get_children()

#func _ready() -> void:
	#var dir = DirAccess.open("user://")
	#var dir_exists = dir.dir_exists("Preliminary Questions")
	#if dir_exists:
	#	null
	#else:
	#	dir.make_dir("Preliminary Questions")
	
	#dir_exists = dir.dir_exists("Preliminary Questions/Junior Questions/Images")
	#if dir_exists:
	#	null
	#else:
	#	dir.make_dir_recursive("Preliminary Questions/Junior Questions/Images")
	
	#dir_exists = dir.dir_exists("Preliminary Questions/Senior Questions/Images")
	#if dir_exists:
	#	null
	#else:
	#	dir.make_dir_recursive("Preliminary Questions/Senior Questions/Images")
	
	#dir_exists = dir.dir_exists("user://Preliminary Questions//Junior Questions/round 1.txt")
	#if !dir_exists:
	#	var file = FileAccess.open("user://Preliminary Questions//Junior Questions/round 1.txt", FileAccess.WRITE)
	#	file.close()
	
	#dir_exists = dir.dir_exists("user://Preliminary Questions//Junior Questions/round 2.txt")
	#if !dir_exists:
	#	var file = FileAccess.open("user://Preliminary Questions//Junior Questions/round 2.txt", FileAccess.WRITE)
	#	file.close()
	
	#dir_exists = dir.dir_exists("user://Preliminary Questions//Senior Questions/round 1.txt")
	#if !dir_exists:
	#	var file = FileAccess.open("user://Preliminary Questions//Senior Questions/round 1.txt", FileAccess.WRITE)
	#	file.close()

func get_questions(_is_senior_round : bool, _round_no : int):
	question_filepath += "Senior Questions/" if _is_senior_round else "Junior Questions/"
	question_filepath += "round " + str(_round_no) + ".txt"
	images_filepath += "Senior Questions/Images/" if _is_senior_round else "Junior Questions/Images/"
	#images_filepath += "round " + str(_round_no) 
	
	var file = FileAccess.open(question_filepath, FileAccess.READ)
	if file == null:
		print("File does not exist")
		return false
	if FileAccess.get_open_error() != OK:
		print("File could be found at " + question_filepath)
		return false
	 
	var is_line := true
	while not file.eof_reached(): 
		if is_line: 
			questions.append(file.get_line())
			is_line = false
		else:
			points.append(int(file.get_line()))
			is_line = true
	
	is_team_input_finished = true
	file.close()
	return true

var i := 0
func _on_line_edit_text_submitted(new_text: String) -> void:
	if !is_team_input_finished:
		if i < 4:
			teams[i] = new_text
			labels[i].text = new_text
			i += 1
		else:
			is_team_input_finished = true
			$Inputs/LineEdit.editable = false
		$Inputs/LineEdit.clear()

func _on_check_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		is_senior_round = true
	else:
		is_senior_round = false

func _on_round_number_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		round_no = 2
	else:
		round_no = 1

func _on_get_questions_button_pressed() -> void:
	if is_team_input_finished:
		var success = get_questions(is_senior_round, round_no)
		if success:
			$"Inputs/Get Questions Button".disabled = true
			input_finished.emit(teams, questions, points, images_filepath, is_senior_round)
		else:
			get_tree().reload_current_scene()
