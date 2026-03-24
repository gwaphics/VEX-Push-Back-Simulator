extends RigidBody2D

func _ready():
	var color = get_parent().get_meta("Color")
	if color == 1:
		$TextureRect.texture = preload("res://Assets/redBlock.png")
	elif color == 2:
		$TextureRect.texture = preload("res://Assets/blueBlock.png")
