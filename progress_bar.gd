extends ProgressBar

signal player_died(name)

var max_health = 3200
var current_health = 800

@export var id := 0

func _ready():
	$HP.text = str(current_health)
	max_value = max_health
	value = current_health

func increase_health(amount: int):
	current_health = clamp(current_health + amount, 0, max_health)
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "value", current_health, 1).set_trans(Tween.TRANS_QUAD)
	

func decrease_health(amount: int):
	current_health = clamp(current_health - amount, 0, max_health)
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "value", current_health, 1).set_trans(Tween.TRANS_QUAD)
	
	if current_health <= 0:
		player_died.emit(id)

func _process(delta: float) -> void:
	$HP.text = str(current_health)
