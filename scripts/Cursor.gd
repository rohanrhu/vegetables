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

extends Sprite

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
    global_position = get_global_mouse_position()

    if Input.is_mouse_button_pressed(1):
        scale = Vector2(1.15, 1.15)
    else:
        scale = Vector2(1, 1)
