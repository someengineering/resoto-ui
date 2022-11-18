extends WizardEditorNode

func serialize() -> Dictionary:
	return base_serialize()


func deserialize(data) -> void:
	base_deserialize(data)
