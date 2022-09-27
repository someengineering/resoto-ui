extends Control

signal delete

var fake_data:= ["aws_ec2_instance", "aws_iam_role", "aws_ec2_keypair"]

func _ready():
	$FilterEditElement/ComboBox.set_items(fake_data)


func _on_DeleteButton_pressed():
	emit_signal("delete")
