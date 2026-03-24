extends StaticBody2D

@onready var timer = $Timer
@onready var tubeStorage = [0,0,0,0,0,0]
var tubeCleared = false

func _ready() -> void:
	timer.wait_time = 0.2
	timer.one_shot = true

	if get_parent().get_meta("RedBottom"):
		tubeStorage = [1,1,1,2,2,2]
	else:
		tubeStorage = [2,2,2,1,1,1]
		
	if is_equal_approx(rad_to_deg(get_parent().rotation), 180) || is_equal_approx(rad_to_deg(get_parent().rotation), -180):
		$"../Blocks".rotation_degrees = 270

func _physics_process(delta: float) -> void:
	updateBlockDisplay()
	
	if Inputs.intakeOn && Inputs.ballStorage.size() < 8 && Inputs.tongueDown == true && timer.is_stopped():
			for body in $MatchLoadTubeZone.get_overlapping_bodies():
				if body.get_parent() == $"../../../Robot":
					intakeFromTube()
					timer.start()
					
	if !tubeCleared:
		for i in (tubeStorage.size()):
			if tubeStorage[i] == 0 && i == tubeStorage.size()-1:
				Inputs.clearedTubeNum += 1
				tubeCleared = true

func intakeFromTube():
	for i in (tubeStorage.size()):
		if tubeStorage[i] == 1:
			Inputs.ballStorage.append(1)
			tubeStorage[i] = 0
			return
		elif tubeStorage[i] == 2:
			Inputs.ballStorage.append(2)
			tubeStorage[i] = 0
			return


func updateBlockDisplay():
	for i in (tubeStorage.size()):
		if tubeStorage[i] == 1:
			get_parent().get_node("Blocks/Block" + str(i + 1)).texture = preload("res://Assets/redBlock.png")
		elif tubeStorage[i] == 2:
			get_parent().get_node("Blocks/Block" + str(i + 1)).texture = preload("res://Assets/blueBlock.png")
		else:
			get_parent().get_node("Blocks/Block" + str(i + 1)).hide()
