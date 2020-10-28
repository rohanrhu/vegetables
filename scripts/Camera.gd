#
# Vegetables - Multiplayer 2D Shooter
# Vegetables is a multiplayer deathmatch shooter game with cute vegetable characters.
#
# Play: https://evrenselkisilik.itch.io/vegetables
# Github: https://github.com/rohanrhu/vegetables
#
# Copyright (C) 2020, Oğuzhan Eroğlu <rohanrhu2@gmail.com> (https://oguzhaneroglu.com)
# Licensed under GNU/GPLv3
#

extends Camera2D

export var spectator_speed = 750
export var zoom_step = 0.1
export var max_zoom = 0.1
export var min_zoom = 5

onready var nPlayer = $"/root/Game/Player"

var addition = Vector2.ZERO

func _process(delta):
    if not ScriptGlobals.is_server:
        return

    var left = Input.get_action_strength("ui_left")
    var right = Input.get_action_strength("ui_right")
    var up = Input.get_action_strength("ui_up")
    var down = Input.get_action_strength("ui_down")

    var velocity = Vector2(right - left, down - up)
    velocity = velocity.normalized()
    velocity *= delta * spectator_speed * zoom

    global_position += velocity

func _physics_process(delta):
    if ScriptGlobals.is_server:
        return

    global_position = nPlayer.global_position
    global_position += addition

func _input(event):
    if not ScriptGlobals.is_server:
        return

    if event is InputEventMouseButton:
        if event.button_index == BUTTON_WHEEL_UP:
            zoom.x -= zoom_step
            zoom.y -= zoom_step
        elif event.button_index == BUTTON_WHEEL_DOWN:
            zoom.x += zoom_step
            zoom.y += zoom_step

        if zoom.x < max_zoom:
            zoom.x = max_zoom
            zoom.y = max_zoom

        if zoom.x > min_zoom:
            zoom.x = min_zoom
            zoom.y = min_zoom
