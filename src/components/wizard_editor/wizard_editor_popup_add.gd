extends WindowDialog

func show_add_popup(incoming_type:int, show_pos:Vector2):
	var normal_type = incoming_type <= 0
	$MarginContainer/VBoxContainer/SectionLabel.visible = normal_type
	$MarginContainer/VBoxContainer/SectionStartButton.visible = normal_type
	$MarginContainer/VBoxContainer/TextStepButton.visible = normal_type
	$MarginContainer/VBoxContainer/QuestionStepButton.visible = normal_type
	$MarginContainer/VBoxContainer/QuestionStepButton.visible = normal_type
	$MarginContainer/VBoxContainer/BackendLabel.visible = normal_type
	$MarginContainer/VBoxContainer/CreateObjectButton.visible = normal_type
	$MarginContainer/VBoxContainer/HandleObjectButton.visible = normal_type
	$MarginContainer/VBoxContainer/OtherLabel.visible = normal_type
	$MarginContainer/VBoxContainer/CommentButton.visible = normal_type
	$MarginContainer/VBoxContainer/ConfigUpdateButton.visible = normal_type
	$MarginContainer/VBoxContainer/AnswerButton.visible = !normal_type
	$MarginContainer/VBoxContainer/PromptButton.visible = normal_type
	$MarginContainer/VBoxContainer/GotoSectionButton.visible = normal_type
	$MarginContainer/VBoxContainer/SaveConfigsButton.visible = normal_type
	$MarginContainer/VBoxContainer/SetVarButton.visible = normal_type
	$MarginContainer/VBoxContainer/CustomSceneButton.visible = normal_type
		
	popup(Rect2(show_pos, Vector2.ONE))
	rect_size = $MarginContainer.rect_size
	
