extends Control

#the signals emmitted to synchronise with the manager node, without entangling code
signal correct_answer() #emitted for every correct answer
signal incorrect_answer(id, stolen) #emitted for every incorrect answer
signal ready_for_question #emitted to ask the manager node for a question to display, since this node contains
#no question but is kept in the manager

@onready var timer_label = $TimerLabel
@onready var question_button = $QuestionButton
@onready var countdown_timer = $CountdownTimer

var answer := "" #displays the answer

var _is_game_started := false #to check if the game has started yet, not necessary but feels cleaner and more intuitive imo
var can_steal := false
var was_stolen := false

@export var wait_time = 30

func  _ready() -> void:
	countdown_timer.wait_time = wait_time

func _on_QuestionButton_pressed(): #called when the button is presse
	if !_is_game_started: #if game has not started yet, starts game and displays an output
		_is_game_started = true
		timer_label.text = "Game start!"
	else: #if game has started
		question_button.disabled = true #disables the button temporarily 
		countdown_timer.start() #starts the timer
		if countdown_timer.paused == true:
			countdown_timer.paused = false
		timer_label.text = "Timer starts!"  #displays a text though it's not really seen
		
		ready_for_question.emit() #tells the manager to display a question

func _process(delta: float) -> void: #updates the countdown text to the timers current time
	if countdown_timer.get_time_left() > 0: #only updayes if the timer is going, otherwise it does not update
		timer_label.text = str(round(countdown_timer.time_left)) #updates the label, and also rounds the time left, kinda clunky

func _input(event: InputEvent) -> void: #called every input
	if countdown_timer.get_time_left() > 0: #only if the timer is running
		#get_time_left() returns the time left on the timer, if the timer is stopped always returns 0
		#so it can be used to check if the timer is running or not
		#it returns a nonzero value if the timer is paused, however, which is useful
		if event.is_action_pressed("yes"): #this is mapped to the 'y' key
			correct_answer.emit() #tells the manager the answer was correct and update health accordingly
			countdown_timer.stop() #stops the timer
		elif event.is_action_pressed("no"): #this is mapped to the 'n' key
			countdown_timer.stop()
			can_steal = true
			
			timer_label.text = "Stealing time!"
			
		if event.is_action_pressed("pause"): #this is mapped to the 'space' key
			countdown_timer.paused = !countdown_timer.paused #toggles the timer on or off
			#if was off, makes it on and vice versa
			#does this by setting it to the reverse value of what it currently is
	
	if can_steal:
		if event.is_action_pressed("yes"):
			was_stolen = true
			timer_label.text = "Sucessfully Stolen!"
		elif event.is_action_pressed("no"):
			was_stolen = false
			timer_label.text = "Incorrect!!"
		#this is to see if it was successfully stolen or not
		if event.is_action_pressed("1"):
			incorrect_answer.emit(1, was_stolen)
			can_steal = false
		elif event.is_action_pressed("2"):
			incorrect_answer.emit(2, was_stolen)
			can_steal = false
		elif event.is_action_pressed("3"):
			incorrect_answer.emit(3, was_stolen)
			can_steal = false
		elif event.is_action_pressed("4"):
			incorrect_answer.emit(4, was_stolen)
			can_steal = false
		elif event.is_action_pressed("0"):
			incorrect_answer.emit(-1, was_stolen)
			can_steal = false
		#to see which team attempted to steal, 0 if none 

func _on_countdown_timer_timeout() -> void: #is called when the timer reaches zero
	print("times up")
	can_steal = true #defaults to incorrect answer
	
	timer_label.text = "Stealing time!"
