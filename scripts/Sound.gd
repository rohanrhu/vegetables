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

extends Node

onready var player = $AudioStreamPlayer

func play_file(file):
	player.stream = load(file)
	player.play()

func stop():
	player.stop()
