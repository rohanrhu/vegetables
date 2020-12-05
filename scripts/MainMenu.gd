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

extends CanvasLayer

var peer: NetworkedMultiplayerENet

func _ready():
    if not OS.is_debug_build() and not ScriptGlobals.is_android:
        Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

    get_tree().connect("connected_to_server", self, "_on_server_connected")
    get_tree().connect("connection_failed", self, "_on_server_failed")

    $Panel/VersionLabel.text = ScriptGlobals.VERSION_STRING

func _on_StartButton_pressed():
    $Panel/StatusLabel.text = "connecting to game.."
    Client.join_game()

func _on_server_connected():
    Client.player_info = {
        id = get_tree().get_network_unique_id(),
        name = $Panel/NameInput.text
    }

    Server.rpc_id(1, "set_player_name", $Panel/NameInput.text)
    get_tree().change_scene("res://scenes/Game.tscn")
    Server.rpc_id(1, "join_game")

func _on_server_failed():
    pass

func _on_IOGamesLink_pressed():
    OS.shell_open("https://iogames.space")

func _on_DiscordLink_pressed():
    OS.shell_open("https://discord.gg/WXg7XXZ")
