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

func _ready():
    print("Vegetables ", ScriptGlobals.VERSION_STRING)

    if "--server" in OS.get_cmdline_args():
        ScriptGlobals.is_server = true
        Server.serve()
    else:
        get_tree().change_scene("res://scenes/MainMenu.tscn")
