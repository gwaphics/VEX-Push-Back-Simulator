extends Control
const SCALE: float = 3.88
const FIELD_HALF_SIZE: float = 72.0  # field goes from -72 to 72
@onready var robot_base := $"../Simulation/Robot/RobotBase"
@onready var x_label := $X
@onready var y_label := $Y
@onready var theta_label := $Theta
@onready var coordinate_label := $Coordinates
@onready var blue_score := $BlueScore
@onready var red_score := $RedScore
@onready var air_psi := $Air
@onready var right_control := $RightControl
@onready var left_control := $LeftControl
@onready var mid_control := $MidControl
@onready var low_control := $LowControl

func disable_blocks(node: Node) -> void:
	for child in node.get_children():
		child.process_mode = Node.PROCESS_MODE_DISABLED

func enable_blocks(node: Node) -> void:
	for child in node.get_children():
		child.process_mode = Node.PROCESS_MODE_INHERIT

func _ready() -> void:
	if Inputs.routeText != "":
		$TextEdit.text = Inputs.routeText
	if Inputs.matchOn:
		$"../Simulation/MatchBlocks".show()
		$"../Simulation/SkillsBlocks".hide()
		enable_blocks($"../Simulation/MatchBlocks")
		disable_blocks($"../Simulation/SkillsBlocks")
	else:
		$"../Simulation/MatchBlocks".hide()
		$"../Simulation/SkillsBlocks".show()
		disable_blocks($"../Simulation/MatchBlocks")
		enable_blocks($"../Simulation/SkillsBlocks")


func _process(delta: float) -> void:
	if robot_base == null:
		return
	var pos: Vector2 = robot_base.global_position / SCALE
	var angle: float = robot_base.rotation
	var display_x: float = pos.x + FIELD_HALF_SIZE - 148.585
	var display_y: float = FIELD_HALF_SIZE - pos.y + 84
	x_label.text = "X: %.2f" % display_x
	y_label.text = "Y: %.2f" % display_y
	theta_label.text = "Theta: %.2f" % rad_to_deg(angle)
	coordinate_label.text = "(%.0f, %.0f, %.0f)" % [display_x, display_y, rad_to_deg(angle)]
	
	air_psi.text = "Air: "+str(Inputs.air)+" psi"
	
	if Inputs.matchOn:
		var red_base = 3*$"../Simulation/RightLongGoal".get_meta("RedScored") + 3*$"../Simulation/LeftLongGoal".get_meta("RedScored") + 3*$"../Simulation/MidGoal".get_meta("RedScored") + 3*$"../Simulation/LowGoal".get_meta("RedScored")
		var blue_base = 3*$"../Simulation/RightLongGoal".get_meta("BlueScored") + 3*$"../Simulation/LeftLongGoal".get_meta("BlueScored") + 3*$"../Simulation/MidGoal".get_meta("BlueScored") + 3*$"../Simulation/LowGoal".get_meta("BlueScored")

		red_score.text = "Red: " + str(red_base + _get_control_bonus("red") + checkPark())
		blue_score.text = "Blue: " + str(blue_base + _get_control_bonus("blue"))
		right_control.text = "Right: " + $"../Simulation/RightLongGoal".get_meta("Control")
		left_control.text = "Left: " + $"../Simulation/LeftLongGoal".get_meta("Control")
		mid_control.text = "Mid: " + $"../Simulation/MidGoal".get_meta("Control")
		low_control.text = "Low: " + $"../Simulation/LowGoal".get_meta("Control")
	else:
		var red_base = $"../Simulation/RightLongGoal".get_meta("RedScored")+$"../Simulation/RightLongGoal".get_meta("BlueScored")+$"../Simulation/LeftLongGoal".get_meta("RedScored")+$"../Simulation/LeftLongGoal".get_meta("BlueScored")+$"../Simulation/MidGoal".get_meta("BlueScored")+$"../Simulation/MidGoal".get_meta("RedScored")+$"../Simulation/LowGoal".get_meta("RedScored")+$"../Simulation/LowGoal".get_meta("BlueScored")

		red_score.text = "Red: " + str(red_base + _get_control_bonus("red") + _get_control_bonus("blue") + checkPark() + 5*Inputs.clearedTubeNum + redParkClear() + blueParkClear())
		blue_score.text = "Blue: N/A"
		right_control.text = "Right: "+$"../Simulation/RightLongGoal".get_meta("Control")
		left_control.text = "Left: "+$"../Simulation/LeftLongGoal".get_meta("Control")
		mid_control.text = "Mid: "+$"../Simulation/MidGoal".get_meta("Control")
		low_control.text = "Low: "+$"../Simulation/LowGoal".get_meta("Control")

func _get_control_bonus(color: String) -> int:
	var bonus = 0
	for goal in [$"../Simulation/RightLongGoal", $"../Simulation/LeftLongGoal", $"../Simulation/MidGoal", $"../Simulation/LowGoal"]:
		if goal.get_meta("Control") == color:
			if Inputs.matchOn == false && goal == $"../Simulation/RightLongGoal" || goal == $"../Simulation/LeftLongGoal":
				bonus += 5
			elif Inputs.matchOn == true && goal == $"../Simulation/MidGoal":
				bonus += 8
			elif Inputs.matchOn == true && goal == $"../Simulation/LowGoal":
				bonus += 6
			else:
				bonus += 10
	return bonus

func checkPark():
	for body in $"../Simulation/Field/RedParkZone".get_overlapping_bodies():
		if body.get_parent() == $"../Simulation/Robot":
			if Inputs.matchOn == true:
				return 8
			else:
				return 15
	return 0
	
func redParkClear():
	var zone_cleared = true
	
	for body in $"../Simulation/Field/RedParkZone".get_overlapping_bodies():
		if body.get_parent().get_parent() == $"../Simulation/SkillsBlocks":
			zone_cleared = false
			break 
	
	if zone_cleared:
		return 5
	return 0
	
func blueParkClear():
	var zone_cleared = true
	
	for body in $"../Simulation/Field/BlueParkZone".get_overlapping_bodies():
		if body.get_parent().get_parent() == $"../Simulation/SkillsBlocks":
			zone_cleared = false
			break 
	
	if zone_cleared:
		return 5
	return 0

func _on_match_button_pressed() -> void:
	Inputs.routeText = $TextEdit.text
	Inputs.air = 100
	Inputs.ballStorage = []
	Inputs.tongueDown = false
	Inputs.autonOn = false
	Inputs.clearedTubeNum = 0
	Inputs.park = false
	get_tree().reload_current_scene()
	$"../Simulation/MatchBlocks".show()
	$"../Simulation/SkillsBlocks".hide()
	enable_blocks($"../Simulation/MatchBlocks")
	disable_blocks($"../Simulation/SkillsBlocks")
	Inputs.matchOn = true

func _on_skills_button_pressed() -> void:
	Inputs.routeText = $TextEdit.text
	Inputs.air = 100
	Inputs.ballStorage = []
	Inputs.tongueDown = false
	Inputs.autonOn = false
	Inputs.clearedTubeNum = 0
	Inputs.park = false
	get_tree().reload_current_scene()
	$"../Simulation/MatchBlocks".hide()
	$"../Simulation/SkillsBlocks".show()
	disable_blocks($"../Simulation/MatchBlocks")
	enable_blocks($"../Simulation/SkillsBlocks")
	Inputs.matchOn = false

func _on_reset_button_pressed() -> void:
	Inputs.routeText = $TextEdit.text
	Inputs.air = 100
	Inputs.ballStorage = []
	Inputs.tongueDown = false
	Inputs.autonOn = false
	Inputs.clearedTubeNum = 0
	Inputs.park = false
	get_tree().reload_current_scene()

func _on_run_code_button_pressed() -> void:
	Inputs.autonOn = !Inputs.autonOn
	if Inputs.autonOn:
		$RunCodeButton.text = "Stop"
	else:
		$RunCodeButton.text = "Start"
