extends Node2D

enum States {IDLE, TALK}
var state:int = States.IDLE setget set_state
var double_blink : bool = false
var is_muted : bool = false
var current_talk_sound : AudioStreamPlayer = null
onready var talk_sounds : Array = $TalkSounds.get_children()

func _ready():
	for ts in talk_sounds:
		ts.connect("finished", self, "talk_sound_finished")
	current_talk_sound = talk_sounds[0]


func mute(_is_muted:bool):
	is_muted = _is_muted
	if is_muted and current_talk_sound.playing:
		current_talk_sound.stop()


func set_state(_state:int):
	state = _state
	if state == States.TALK:
		$WizardHead/Mouth.animation = "talk"
		if not is_muted:
			play_talk_sound()
	elif state == States.IDLE:
		$WizardHead/Mouth.animation = "neutral"
		#current_talk_sound.stop()


func _on_AnimationPlayer_animation_finished(_anim_name):
	if state == States.IDLE:
		$AnimationPlayer.play("Idle")
	elif state == States.TALK:
		$AnimationPlayer.play("Talk")


func _on_BlinkTimer_timeout():
	$WizardHead/Eyes.animation = "blink"
	$NormalEyeTimer.start()


func _on_NormalEyeTimer_timeout():
	$WizardHead/Eyes.animation = "normal"
	if not double_blink:
		double_blink = randf() > 0.8
		$BlinkTimer.wait_time = rand_range(3,3.2) if state == States.IDLE else rand_range(1.4, 2)
	if double_blink:
		double_blink = false
		$BlinkTimer.wait_time = 0.1
		
	$BlinkTimer.start()


func play_talk_sound():
	var new_talk_sound : AudioStreamPlayer = current_talk_sound
	while new_talk_sound == current_talk_sound:
		new_talk_sound = talk_sounds[randi()%talk_sounds.size()]
	current_talk_sound = new_talk_sound
	current_talk_sound.play()


func talk_sound_finished():
	if state == States.TALK:
		play_talk_sound()
