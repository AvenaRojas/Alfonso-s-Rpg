extends Control

signal textbox_closed
signal textbox_finished

@export var enemy: Resource = null

var current_player_health = 0
var current_enemy_health = 0
var text_speed = 0.01
var is_busy = false

func _ready():
	$MainMusic.play()
	$AnimationPlayer.play("Alfonso_idle")
	$EnemyAnimationPlayer.play("Enemy_Idle")
	
	set_health($EnemyContainer/Control/ProgressBar, enemy.health, enemy.health)
	set_health($PlayerPanel/PlayerData/Control/ProgressBar, State.current_health, State.max_health)
	
	$EnemyContainer/Control/Enemy.texture = enemy.texture
	
	current_enemy_health =  enemy.health
	current_player_health = State.current_health
	
	$TextBox.hide()
	$ActionsPanel.hide()
	
	set_buttons_disabled(true)
	is_busy = true
	display_text("A wild %s stops you... with his weird dance" %enemy.name)
	is_busy = false
	await textbox_closed
	set_buttons_disabled(false)
	
	$ActionsPanel.show()
	await get_tree().create_timer(.3).timeout
	$ActionsPanel/Actions/Attack.grab_focus()
	
func set_buttons_disabled(disabled: bool):
	$ActionsPanel/Actions/Attack.disabled = disabled
	$ActionsPanel/Actions/Defend.disabled = disabled
	$ActionsPanel/Actions/Run.disabled = disabled

func set_health(progress_bar,health, max_health):
	progress_bar.value = health
	progress_bar.max_value = max_health
	progress_bar.get_node("Label").text = "HP: %d/%d" % [health, max_health]
	
func _input(_event):
	if is_busy and (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
		$DontPress.play()
		await get_tree().create_timer(.1).timeout
		return
	if (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and $TextBox.visible:
		$ButtonPressed.play()
		$TextBox.hide()
		emit_signal("textbox_closed")
	if $ActionsPanel.visible:
		if Input.is_action_just_pressed("ui_left"):
			change_focus(-1)
		elif Input.is_action_just_pressed("ui_right"):
			change_focus(1)
		
func change_focus(direction: int):
	var current_focus = get_viewport().gui_get_focus_owner()
	var buttons = [$ActionsPanel/Actions/Attack, $ActionsPanel/Actions/Defend ,$ActionsPanel/Actions/Run]
	var current_index = buttons.find(current_focus)
	
	if current_index != -1:
		var next_index = (current_index + direction) % buttons.size()
		buttons[next_index].grab_focus()
		
func display_text(text):
	set_buttons_disabled(true)
	$TextBox.show() 
	$TextBox/RichTextLabel.bbcode_text = text
	$TextBox/RichTextLabel.visible_characters = 0 
	
	var tween = create_tween()
	var text_length = text.length()
	var tween_duration = text_speed * text_length
	
	$TextSound.play()
	tween.tween_method(
		func(value): 
			$TextBox/RichTextLabel.visible_characters = int(value),
		0.0,
		text_length,
		tween_duration
	)
	
	await tween.finished
	$TextSound.stop()
	emit_signal("textbox_finished")
	
func enemy_turn():
	is_busy = true
	display_text("%s slashes Alfonso..." % enemy.name)
	$EnemyAnimationPlayer.play("Enemy_attacks")
	
	await get_tree().create_timer(.4).timeout
	
	current_player_health = max(0, current_player_health - enemy.damage)
	set_health($PlayerPanel/PlayerData/Control/ProgressBar, current_player_health, State.current_health)
	
	display_text("%s slashes Alfonso... it's effective" %enemy.name)
	$Hurt.play()
	$AnimationPlayer.play("Alfonso_hurt")
	
	await $AnimationPlayer.animation_finished
	
	$AnimationPlayer.play("Alfonso_idle")
	$EnemyAnimationPlayer.play("Enemy_Idle")
	is_busy = false
	
	await textbox_closed
	
	is_busy = true
	display_text("%s dealed %d damage with... his yoyo??" % [enemy.name,enemy.damage])
	
	await get_tree().create_timer(.4).timeout
	is_busy = false
	
	await textbox_closed
	await get_tree().create_timer(.3).timeout
	set_buttons_disabled(false)
	
func _on_run_pressed() -> void:
	set_buttons_disabled(true)
	is_busy = true
	display_text("You lil Coward, you can't go, you're a cardboard box")
	await textbox_finished
	is_busy = false
	await textbox_closed
	await get_tree().create_timer(.3).timeout
	set_buttons_disabled(false)
	#Space for an animation that shows the discomfort with that decision, so much that the enemy and the player disagrees

func _on_attack_pressed() -> void:
	is_busy = true
	display_text("You fall into %s..." %enemy.name)
	$AnimationPlayer.play("Alfonso_attacks")
	
	await get_tree().create_timer(.6).timeout
	
	current_enemy_health = max(0, current_enemy_health - State.damage)
	set_health($EnemyContainer/Control/ProgressBar, current_enemy_health, enemy.health)
	
	display_text("You fall into %s... it's effective" %enemy.name)
	$Hurt.play()
	$EnemyAnimationPlayer.play("Enemy_Hurt")
	
	await $AnimationPlayer.animation_finished
	$EnemyAnimationPlayer.play("Enemy_Idle")
	is_busy = false
	
	await textbox_closed
	
	is_busy = true
	display_text("You dealed *Surprisely* %d damage!!!" % State.damage)
	await textbox_finished
	$AnimationPlayer.play("Alfonso_idle")
	
	is_busy = false
	await textbox_closed
	enemy_turn()
	
