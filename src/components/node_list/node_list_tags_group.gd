extends PanelContainer

signal update_tags
signal delete_tags
signal request_all_tag_keys

var tag_keys : Array = []

onready var add_btn := $TagTitleBar/AddTagButton

onready var new_tag_popup := $AddTagPopup
onready var new_tag_var_edit := $AddTagPopup/AddTagData/NewTagVariableEdit
onready var new_tag_val_edit := $AddTagPopup/AddTagData/NewTagValueEdit

onready var change_tag_popup := $UpdateCreateTagPopup
onready var change_tag_var_combo := $UpdateCreateTagPopup/ChangeTagData/UpdateVariableCombo
onready var change_tag_val_edit := $UpdateCreateTagPopup/ChangeTagData/UpdateTagValueEdit

onready var del_tag_popup := $DeleteTagPopup
onready var del_tag_var_combo := $DeleteTagPopup/DeleteTagData/DeleteTagsComboBox


func _on_AddTagButton_pressed():
	change_tag_popup.hide()
	del_tag_popup.hide()
	new_tag_var_edit.text = ""
	new_tag_val_edit.text = ""
	new_tag_popup.popup(Rect2(rect_global_position+Vector2(0, add_btn.rect_size.y+12), Vector2(rect_size.x, 10)))


func _on_DeleteTagButton_pressed():
	emit_signal("request_all_tag_keys")
	del_tag_var_combo.items = tag_keys
	new_tag_popup.hide()
	change_tag_popup.hide()
	del_tag_var_combo.text = ""
	del_tag_popup.popup(Rect2(rect_global_position+Vector2(0, add_btn.rect_size.y+12), Vector2(rect_size.x, 10)))


func _on_EditTagsButton_pressed():
	emit_signal("request_all_tag_keys")
	change_tag_var_combo.items = tag_keys
	del_tag_popup.hide()
	new_tag_popup.hide()
	change_tag_var_combo.text = ""
	change_tag_val_edit.text = ""
	change_tag_popup.popup(Rect2(rect_global_position+Vector2(0, add_btn.rect_size.y+12), Vector2(rect_size.x, 10)))


func _on_PopupDeleteTagButton_pressed():
	if del_tag_var_combo.text == "":
		_g.emit_signal("add_toast", "Tag name can not be empty!", "", 2, self, 2)
		return
	# HANDLE DELETION
	emit_signal("delete_tags", del_tag_var_combo.text)
	del_tag_popup.hide()


func _on_PopupUpdateTagButton_pressed():
	if change_tag_var_combo.text == "":
		_g.emit_signal("add_toast", "Tag name can not be empty!", "", 2, self, 2)
		return
	# HANDLE UPDATE
	emit_signal("update_tags", change_tag_var_combo.text, change_tag_val_edit.text)
	change_tag_popup.hide()


func _on_PopupAddTagButton_pressed():
	if new_tag_var_edit.text == "":
		_g.emit_signal("add_toast", "Tag name can not be empty!", "", 2, self, 2)
		return
	# HANDLE NEW/ADD
	emit_signal("update_tags", new_tag_var_edit.text, new_tag_val_edit.text)
	new_tag_popup.hide()
