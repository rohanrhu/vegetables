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

var name_input_y = 0

var is_connecting = false

func _ready():
    if not OS.is_debug_build() and not ScriptGlobals.is_android:
        Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

    get_tree().connect("connected_to_server", self, "_on_server_connected")
    get_tree().connect("connection_failed", self, "_on_server_failed")

    $Panel/VersionLabel.text = ScriptGlobals.VERSION_STRING

    name_input_y = $Panel/NameInput.rect_position.y

func _process(delta: float):
    if OS.get_virtual_keyboard_height() > 0:
        $Panel/NameInput.rect_position.y = 150
    else:
        $Panel/NameInput.rect_position.y = name_input_y

func _on_StartButton_pressed():
    if is_connecting == true:
        return

    is_connecting = true

    $Panel/StatusLabel.text = "Connecting to game.."

    var name = $Panel/NameInput.text.strip_edges(true, true)

    Client.player_info = {
        id = 0,
        name = name
    }

    Client.join_game()

func _on_server_connected():
    $Panel/StatusLabel.text = "Connected! Loading..."

    var name = $Panel/NameInput.text.strip_edges(true, true)

    if name == "":
        name = "Player"

    Client.player_info["id"] = get_tree().get_network_unique_id()

func _on_server_failed():
    $Panel/StatusLabel.text = "Connection failed!"
    is_connecting = false

func _on_IOGamesLink_pressed():
    OS.shell_open("https://iogames.space")

func _on_DiscordLink_pressed():
    OS.shell_open("https://discord.gg/WXg7XXZ")
