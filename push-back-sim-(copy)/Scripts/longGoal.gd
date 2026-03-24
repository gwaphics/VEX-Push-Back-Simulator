extends StaticBody2D
@onready var bottomScoreZone = $"../BottomScoreZone"
@onready var topScoreZone = $"../TopScoreZone"
@onready var timer = $Timer
# 0 = nothing | 1 = red | 2 = blue
var scored = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

func _ready() -> void:
	timer.wait_time = 0.1
	timer.one_shot = true

func _physics_process(delta: float) -> void:
	if Inputs.score && Inputs.ballStorage.size() > 0 && timer.is_stopped():
		var angle: float = $"../../Robot/RobotBase".rotation_degrees
		# Check bottom zone
		for body in bottomScoreZone.get_overlapping_bodies():
			if body.get_parent() == $"../../Robot":
				if angle > 160 || angle < -160:
					scoreOnLow()
					timer.start()
		# Check top zone
		for body in topScoreZone.get_overlapping_bodies():
			if body.get_parent() == $"../../Robot":
				if angle < 20 && angle > -20:
					scoreOnHigh()
					timer.start()

var ejected_color = 0

func scoreOnLow():
	var color = Inputs.ballStorage.pop_front()
	ejected_color = 0
	
	for i in range(scored.size()):
		if scored[i] == 0:
			scored.remove_at(i)
			break
		if i == scored.size() - 1:
			ejected_color = scored.back()
			scored.pop_back()
	
	scored.push_front(color)
	redrawBlocks()
	checkScore(color)

func scoreOnHigh():
	var color = Inputs.ballStorage.pop_front()
	ejected_color = 0
	
	for i in range(scored.size() - 1, -1, -1):
		if scored[i] == 0:
			scored.remove_at(i)
			break
		if i == 0:
			ejected_color = scored.front()
			scored.pop_front()
	
	scored.push_back(color)
	redrawBlocks()
	checkScore(color)

func checkScore(color):
	if color == 1:
		get_parent().set_meta("RedScored", get_parent().get_meta("RedScored") + 1)
	elif color == 2:
		get_parent().set_meta("BlueScored", get_parent().get_meta("BlueScored") + 1)
	
	# Subtract the ejected block from score
	if ejected_color == 1:
		get_parent().set_meta("RedScored", get_parent().get_meta("RedScored") - 1)
	elif ejected_color == 2:
		get_parent().set_meta("BlueScored", get_parent().get_meta("BlueScored") - 1)
	
	if ($"../Blocks/Block6".visible && $"../Blocks/Block7".visible && $"../Blocks/Block8".visible):
		if ($"../Blocks/Block6".texture == $"../Blocks/Block7".texture && $"../Blocks/Block7".texture == $"../Blocks/Block8".texture):
			if ($"../Blocks/Block6".texture == preload("res://Assets/redBlock.png")):
				get_parent().set_meta("Control", "red")
			else:
				get_parent().set_meta("Control", "blue")
		else:
			get_parent().set_meta("Control", "none")

func redrawBlocks():
	for i in range(scored.size()):
		var block = get_parent().get_node("Blocks/Block" + str(i + 1))
		if scored[i] != 0:
			if scored[i] == 1:
				block.texture = preload("res://Assets/redBlock.png")
			else:
				block.texture = preload("res://Assets/blueBlock.png")
			block.show()
		else:
			block.hide()
