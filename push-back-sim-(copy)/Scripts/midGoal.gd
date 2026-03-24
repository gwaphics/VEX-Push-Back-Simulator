extends StaticBody2D
@onready var bottomScoreZone = $"../BottomScoreZone"
@onready var topScoreZone = $"../TopScoreZone"
@onready var timer = $Timer
# 0 = nothing | 1 = red | 2 = blue
var scored = [0, 0, 0, 0, 0, 0, 0]

func _ready() -> void:
	timer.wait_time = 0.1
	timer.one_shot = true
	
	add_to_group("low_goals")
	timer.wait_time = 0.1
	timer.one_shot = true

func _physics_process(delta: float) -> void:
	# Mid Goal
	if is_equal_approx(rad_to_deg(get_parent().rotation), -135) || is_equal_approx(rad_to_deg(get_parent().rotation), 45):
		if Inputs.midScore && Inputs.ballStorage.size() > 0 && timer.is_stopped():
			var angle: float = $"../../Robot/RobotBase".rotation_degrees
			# Check bottom zone
			for body in bottomScoreZone.get_overlapping_bodies():
				if body.get_parent() == $"../../Robot":
					if angle > -155 || angle < -115:
						scoreOnLow()
						timer.start()
			# Check top zone
			for body in topScoreZone.get_overlapping_bodies():
				if body.get_parent() == $"../../Robot":
					if angle > 25 || angle < 65:
						scoreOnHigh()
						timer.start()
	# Low Goal
	if is_equal_approx(rad_to_deg(get_parent().rotation), 135) || is_equal_approx(rad_to_deg(get_parent().rotation), -45):
		if Inputs.extake && Inputs.ballStorage.size() > 0 && timer.is_stopped():
			var angle: float = $"../../Robot/RobotBase".rotation_degrees
			for body in bottomScoreZone.get_overlapping_bodies():
				if body.get_parent() == $"../../Robot":
					if angle < -25 || angle > -65:
						scoreOnLow()
						timer.start()
			for body in topScoreZone.get_overlapping_bodies():
				if body.get_parent() == $"../../Robot":
					if angle < 155 || angle > 115:
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
	
	if ejected_color == 1:
		get_parent().set_meta("RedScored", get_parent().get_meta("RedScored") - 1)
	elif ejected_color == 2:
		get_parent().set_meta("BlueScored", get_parent().get_meta("BlueScored") - 1)
	
	if Inputs.matchOn:
		var red_count = scored.count(1)
		var blue_count = scored.count(2)
		if red_count == 0 and blue_count == 0:
			get_parent().set_meta("Control", "none")
		elif red_count > blue_count:
			get_parent().set_meta("Control", "red")
		elif blue_count > red_count:
			get_parent().set_meta("Control", "blue")
		else:
			# tied
			get_parent().set_meta("Control", "none")
	else:
		# All 7 slots must be filled with the same color
		if scored.all(func(x): return x == 1):
			get_parent().set_meta("Control", "red")
		elif scored.all(func(x): return x == 2):
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
