#
# Vegetables - Multiplayer 2D Shooter
# Vegetables is a multiplayer deathmatch shooter game with cute vegetable characters.
#
# Play: https://evrenselkisilik.itch.io/vegetables
# Github: https://github.com/rohanrhu/vegetables
#
# Copyright (C) 2020, Oğuzhan Eroğlu <rohanrhu2@gmail.com> (https://oguzhaneroglu.com)
# Lİcensed under GNU/GPLv3
#

extends Sprite

export var duration = 8000

var is_placed = false
onready var create_time = OS.get_ticks_msec()

func _ready():
    pass

func _process(delta):
    if is_placed and OS.get_ticks_msec() - create_time >= duration:
        queue_free()

func place():
    is_placed = true
