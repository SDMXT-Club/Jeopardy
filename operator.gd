extends Control

#this signal finishes once each of the inputs are gotten, and tells the manager/parent everything it needs to know
signal input_finished(_sr_questions, _jr_questions, _sr_points, _jr_points, _sr_teams, _jr_teams)

var sr_questions = [] #array for holding questions, reads it from text file
var jr_questions = [] #array for holding junior questions, reads it from text fil
var sr_points = [] #array for corresponding points, reads it from alternating lines of text file
var jr_points = []
@export var sr_teams = ["", "", "", ""] #array for holding senior teams
@export var jr_teams = ["", "", "", ""] #array for holding juniour teams, both are export variables

@onready var labels = $Labels #labels to show team names

func _ready() -> void:
	#when the scene is ready, it opens the text file and reads each line
	#every other line is a question, starting from first
	#every other line is the above question's corresponding points, after that
	var file = FileAccess.open("res://Builds/senior questions.txt", FileAccess.READ) #the file is saved in "res://Builds/questions.txt" 
	var is_line := true #to check whether it's a question or a point, a bit clunky implementation 
	while not file.eof_reached(): #to check every single line in file, allows for modular inputting
		if is_line: #checks if question or point
			sr_questions.append(file.get_line())#appends the question to the array
			is_line = false#if this line was a question next must be points
		else:
			sr_points.append(int(file.get_line()))#appends the corresponding points to the array, each index in points array
			is_line = true#corresponds to each index in questions array
	file.close()
	
	var file1 = FileAccess.open("res://Builds/junior questions.txt", FileAccess.READ) #the file is saved in "res://Builds/questions.txt" 
	var is_line1 := true #to check whether it's a question or a point, a bit clunky implementation 
	while not file1.eof_reached(): #to check every single line in file, allows for modular inputting
		if is_line1: #checks if question or point
			jr_questions.append(file1.get_line())#appends the question to the array
			is_line1 = false#if this line was a question next must be points
		else:
			jr_points.append(int(file1.get_line()))#appends the corresponding points to the array, each index in points array
			is_line1 = true#corresponds to each index in questions array
	file1.close()

var num1 := 0#another clunky implementation to input the teams
var num2 := 0
func _on_line_edit_text_submitted(new_text: String) -> void:#is called everytime the text field has a new input
	if num1 < 4:#responsible for inputting the senior team names
		sr_teams[num1] = new_text
		labels.get_child(num1).text = new_text#updates also the label
		num1 += 1
	elif num2 < 4:#responsible for inputting the juniour team teams
		jr_teams[num2] = new_text
		labels.get_child(num2 + 4).text = new_text
		num2 += 1
	#print(sr_teams, num1, jr_teams, num2)
	$Control/LineEdit.clear()#resets the text field for text input
	
	if num1 >= 4 and num2 >= 4:#if we're done with inputting we'll emit the signal and move onto the next stage
		input_finished.emit(sr_questions, sr_points, jr_questions, jr_points, sr_teams, jr_teams)
