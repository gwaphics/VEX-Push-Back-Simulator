extends RigidBody2D
const SCALE: float = 3.88
const FIELD_HALF_SIZE: float = 72.0
@export var move_force: float = 8333.33
@export var turn_torque: float = 133333.33
@export var max_turn_speed: float = 5.0
@onready var intake := $IntakeZone
@onready var textEdit = $"../../../GUI/TextEdit"
@onready var wait_timer := $Timer
var lineNum = 0
var route = []
var move_timeout: float = 0.0
enum AutoState { TURNING_TO_POINT, MOVING, WAITING }
var auto_state = AutoState.TURNING_TO_POINT
var wasAutonOn = false
var extake_cooldown: float = 0.0

func _ready():
	wait_timer.one_shot = true

func _physics_process(delta: float) -> void:
	if Inputs.intakeOn && Inputs.ballStorage.size() < 8:
		for body in intake.get_overlapping_bodies():
			if body.get_parent().get_parent() == $"../../MatchBlocks" || body.get_parent().get_parent() == $"../../SkillsBlocks":
				body.get_parent().queue_free()
				Inputs.ballStorage.append(body.get_parent().get_meta("Color"))
	$IntakeCapacity.text = str(Inputs.ballStorage.size()) + "/8"
	
	if extake_cooldown > 0.0:
		extake_cooldown -= delta

	if Inputs.extake && Inputs.ballStorage.size() > 0 && extake_cooldown <= 0.0:
		if not _is_low_goal_scoring():
			extake_cooldown = 0.1
			var colorOfBlock = Inputs.ballStorage[-1]
			Inputs.ballStorage.remove_at(Inputs.ballStorage.size() - 1)

			var block_scene = preload("res://Scenes/block.tscn")
			var block = block_scene.instantiate()
			block.set_meta("Color", colorOfBlock)
			block.scale = Vector2(0.25, 0.25)

			if Inputs.matchOn:
				$"../../MatchBlocks".add_child(block)
			else:
				$"../../SkillsBlocks".add_child(block)
			block.global_position = intake.global_position + (-transform.y * 25.0)
		
	if Inputs.tongueDown == false:
		$Tongue.hide()
		$TongueCol.disabled = true
	else:
		$Tongue.show()
		$TongueCol.disabled = false
	
	if Inputs.autonOn:
		if not wasAutonOn:
			getRoute()
			auto_state = AutoState.TURNING_TO_POINT
			wasAutonOn = true
		processCommands()
		match auto_state:
			AutoState.TURNING_TO_POINT:
				turnToPoint()
				if isFacing():
					auto_state = AutoState.MOVING
			AutoState.MOVING:
				moveToPoint()
			AutoState.WAITING:
				if wait_timer.is_stopped():
					route.remove_at(0)
					auto_state = AutoState.TURNING_TO_POINT
	else:
		wasAutonOn = false
		var turn_input := Input.get_axis("turn_left", "turn_right")
		apply_torque(turn_input * turn_torque)
		var move_input := Input.get_axis("move_forward", "move_backward")
		apply_central_force(transform.y * move_input * move_force)

func getRoute():
	route.clear()
	for i in range(textEdit.get_line_count()):
		var line_text = textEdit.get_line(i)
		if line_text == "":
			pass
		elif line_text.begins_with("wait("):
			var ms = float(line_text.substr(5, line_text.length() - 6))
			route.append({"type": "wait", "duration": ms / 1000.0})
		elif line_text[0] == "(":
			var line = line_text.substr(1, line_text.length() - 2)
			var parts = line.split(",")
			var direction = parts[2].strip_edges().to_lower()
			var reverse = direction == "b"
			var timeout = float(parts[3].strip_edges()) / 1000.0 if parts.size() >= 4 else 0.0
			route.append({"type": "point", "x": float(parts[0]), "y": float(parts[1]), "reverse": reverse, "timeout": timeout})
		elif line_text.begins_with("//"):
			pass
		else:
			var parts = line_text.split("=")
			route.append({"type": "command", "variable": parts[0].strip_edges(), "value": parts[1].strip_edges()})

func processCommands():
	if auto_state == AutoState.WAITING:
		return
	while not route.is_empty() and route[0].get("type") == "command":
		var cmd = route[0]
		var val = cmd["value"] == "true"
		match cmd["variable"]:
			"intakeOn":
				Inputs.intakeOn = val
			"extake":
				Inputs.extake = val
			"score":
				Inputs.score = val
			"midScore":
				Inputs.midScore = val
			"tongueDown":
				Inputs.tongueDown = val
		route.remove_at(0)
	if not route.is_empty() and route[0].get("type") == "wait":
		wait_timer.start(route[0]["duration"])
		auto_state = AutoState.WAITING

func getDistance():
	var targetX = (route[0]["x"] - FIELD_HALF_SIZE + 148.585) * SCALE
	var targetY = (FIELD_HALF_SIZE - route[0]["y"] + 84) * SCALE
	var dx = targetX - self.global_position.x
	var dy = targetY - self.global_position.y
	return sqrt(dx * dx + dy * dy)

func turnToPoint():
	move_timeout = 0.0
	if route.is_empty():
		return
	var targetX = (route[0]["x"] - FIELD_HALF_SIZE + 148.585) * SCALE
	var targetY = (FIELD_HALF_SIZE - route[0]["y"] + 84) * SCALE
	var angle_to_target = (Vector2(targetX, targetY) - self.global_position).angle()
	var forward_angle = self.rotation - PI / 2.0
	var angle_diff: float
	if route[0].get("reverse", false):
		angle_diff = wrapf(angle_to_target - forward_angle - PI, -PI, PI)
	else:
		angle_diff = wrapf(angle_to_target - forward_angle, -PI, PI)
	if abs(angle_diff) < 0.05:
		angular_velocity = 0.0
	else:
		angular_velocity = clamp(angle_diff * 5.0, -max_turn_speed, max_turn_speed)

func isFacing() -> bool:
	if route.is_empty():
		return false
	var targetX = (route[0]["x"] - FIELD_HALF_SIZE + 148.585) * SCALE
	var targetY = (FIELD_HALF_SIZE - route[0]["y"] + 84) * SCALE
	var angle_to_target = (Vector2(targetX, targetY) - self.global_position).angle()
	var forward_angle = self.rotation - PI / 2.0
	var angle_diff: float
	if route[0].get("reverse", false):
		angle_diff = wrapf(angle_to_target - forward_angle - PI, -PI, PI)
	else:
		angle_diff = wrapf(angle_to_target - forward_angle, -PI, PI)
	return abs(angle_diff) < 0.05

func moveToPoint():
	if route.is_empty():
		return

	if move_timeout == 0.0 and route[0].get("timeout", 0.0) > 0.0:
		move_timeout = route[0]["timeout"]

	if move_timeout > 0.0:
		move_timeout -= get_physics_process_delta_time()
		if move_timeout <= 0.0:
			move_timeout = 0.0
			linear_velocity = linear_velocity * 0.85
			route.remove_at(0)
			auto_state = AutoState.TURNING_TO_POINT
			return

	var distance = getDistance()
	if distance < 10.0:
		linear_velocity = linear_velocity * 0.85
		move_timeout = 0.0
		route.remove_at(0)
		auto_state = AutoState.TURNING_TO_POINT
		return
	var proximity_scale = clamp(distance / 200.0, 0.2, 1.0)
	if route[0].get("reverse", false):
		apply_central_force(transform.y * move_force * proximity_scale)
	else:
		apply_central_force(-transform.y * move_force * proximity_scale)
		
func _is_low_goal_scoring() -> bool:
	var angle: float = self.rotation_degrees
	for goal in get_tree().get_nodes_in_group("low_goals"):
		var goal_rot = rad_to_deg(goal.get_parent().rotation)
		if abs(goal_rot - 135) < 1.0 or abs(goal_rot + 45) < 1.0:
			for body in goal.bottomScoreZone.get_overlapping_bodies():
				if body.get_parent() == get_parent():
					if angle > -65 && angle < -25:
						return true
			for body in goal.topScoreZone.get_overlapping_bodies():
				if body.get_parent() == get_parent():
					if angle > 115 && angle < 155:
						return true
	return false
