extends Node

# 0 = nothing | 1 = red | 2 = blue
var ballStorage = []
var air = 100
var autonOn = false
var routeText = ""
var matchOn = true
var park = false
var clearedTubeNum = 0

var intakeOn = false
var extake = false
var score = false
var midScore = false
var tongueDown = false

func _physics_process(delta: float) -> void:
	if autonOn:
		pass
	else:
		if Input.is_action_pressed("intake"):
			intakeOn = true
		elif Input.is_action_pressed("extake"):
			extake = true
		elif Input.is_action_pressed("score"):
			score = true
		elif Input.is_action_pressed("mid_score"):
			midScore = true
		else:
			intakeOn = false
			extake = false
			score = false
			midScore = false
			
		if Input.is_action_just_pressed("tongue"):
			tongueDown = !tongueDown
			if tongueDown:
				air -= 5
	
