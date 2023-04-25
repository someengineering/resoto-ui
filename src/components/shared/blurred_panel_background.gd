extends Node2D

# This is used as a solution to have the nice looking background blur behind certain panels using GLES2
# Attach it to Panels or other Control nodes.

export (bool) var start_visible := false

onready var backbuffers := [$BackBufferCopy_X1, $BackBufferCopy_X2, $BackBufferCopy_Y1, $BackBufferCopy_Y2]
onready var panels := [$BackBufferCopy_X1/BlurEffect, $BackBufferCopy_X2/BlurEffect, $BackBufferCopy_Y1/BlurEffect, $BackBufferCopy_Y2/BlurEffect]
onready var parent : Control = get_parent()


func _ready():
	if not parent.visible:
		set_process(false)
	parent.connect("visibility_changed", self, "on_parent_visibility_changed")


func on_parent_visibility_changed():
	set_process(parent.visible)


func _process(_delta):
	var parent_global_rect : Rect2 = parent.get_global_rect()
	for backbuffer in backbuffers:
		backbuffer.rect.size = parent_global_rect.size
	
	for panel in panels:
		(panel as Panel).rect_size = parent_global_rect.size
