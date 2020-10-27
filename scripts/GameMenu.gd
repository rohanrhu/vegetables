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

extends Control

export var is_opened = false

func _ready():
    $Panel/VersionLabel.text = ScriptGlobals.VERSION_STRING

func open():
    is_opened = true
    visible = true

func close():
    is_opened = false
    visible = false

func toggle():
    is_opened = !is_opened
    visible = !visible

func _on_CancelButton_pressed():
    close()

func _on_MainMenuButton_pressed():
    Client.peer.disconnect_from_host()
    get_tree().change_scene("res://scenes/MainMenu.tscn")
