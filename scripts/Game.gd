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

extends Node2D

var script_globals = preload("res://scripts/ScriptGlobals.gd")

onready var player = $Player
onready var fps_label = $CanvasLayer/FPSLabel
onready var kills_number_label = $CanvasLayer/KillsInfo/KillsNumberLabel
onready var camera_container = $CameraContainer
onready var leaderBoard_label: RichTextLabel = $CanvasLayer/Leaderboard/Label
onready var gameMenu = $CanvasLayer/GameMenu
onready var chat = $CanvasLayer/Chat
onready var chat_label: RichTextLabel = $CanvasLayer/Chat/Label
onready var chat_input: LineEdit = $CanvasLayer/Chat/Input
onready var mobileLayout = $CanvasLayer/MobileLayout
onready var inventory = $CanvasLayer/Inventory

func _ready():
    if ScriptGlobals.is_server:
        $CanvasLayer/Inventory.visible = false
        mobileLayout.visible = false
        return

    $Prototypes.visible = false

    Server.rpc_id(1, "sync_position")
    Server.rpc_id(1, "sync_players")
    Server.rpc_id(1, "sync_bloods")
    Server.rpc_id(1, "sync_loot_boxes")

func _process(delta):
    fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

    if Input.is_action_just_pressed("ui_cancel"):
        gameMenu.toggle()

func killed(id, by):
    var player
    var is_me = false

    if id == get_tree().get_network_unique_id():
        is_me = true
        player = get_tree().get_root().get_node_or_null("/root/Game/Player")
    else:
        player = get_tree().get_root().get_node_or_null("/root/Game/Players/"+str(id))

    if not player:
        return true

    var game = get_tree().get_root().get_node("/root/Game")

    game.create_blood(player.global_position)

    if is_me:
        player.set_kills(0)
        player.items = {0: 0}
        player.item = ScriptGlobals.ITEM.NONE
        player.switch_weapon(player.item)
        inventory.clear()
    elif by == get_tree().get_network_unique_id():
        game.get_node("Player").increase_kills()

        $"/root/Game/Sounds/Score".stop()
        $"/root/Game/Sounds/Score".play()

    player.switch_weapon(ScriptGlobals.ITEM.NONE)

func create_player():
    var player = self.player.duplicate()
    player.is_me = false
    $Players.add_child(player)

    return player

func create_blood(blood_position):
    var blood = $Blood.duplicate()
    blood.rotation = randf() * (PI * 2)
    blood.visible = true
    blood.global_position = blood_position
    $Bloods.add_child(blood)
    blood.place()

func set_health(health, max_health):
    var bar_size = $"/root/Game/CanvasLayer/HealthBar/PercentSize".get_size()
    var percent_size = $CanvasLayer/HealthBar/Percent.get_size()
    var width = (bar_size.x * health) / max_health

    $CanvasLayer/HealthBar/Percent.set_size(Vector2(width, percent_size.y))

func set_leaderboard(leaders):
    leaderBoard_label.clear()

    leaderBoard_label.push_table(3)

    leaderBoard_label.push_cell()
    leaderBoard_label.push_color(Color.yellow)
    leaderBoard_label.add_text("Rank"+"   ")
    leaderBoard_label.pop()
    leaderBoard_label.pop()
    leaderBoard_label.push_cell()
    leaderBoard_label.push_color(Color.yellow)
    leaderBoard_label.add_text("Player"+"                    ")
    leaderBoard_label.pop()
    leaderBoard_label.pop()
    leaderBoard_label.push_cell()
    leaderBoard_label.push_color(Color.yellow)
    leaderBoard_label.add_text("Kills"+"           ")
    leaderBoard_label.pop()
    leaderBoard_label.pop()

    var rank = 1
    var player

    for leader in leaders:
        player = get_node_or_null("Players/" + str(leader[0]))

        leaderBoard_label.push_cell()
        leaderBoard_label.add_text(str(rank))
        leaderBoard_label.pop()

        leaderBoard_label.push_cell()
        if player:
            leaderBoard_label.add_text(player.player_info["name"])
        else:
            leaderBoard_label.add_text(Client.player_info["name"])
        leaderBoard_label.pop()

        leaderBoard_label.push_cell()
        leaderBoard_label.add_text(str(leader[1]))
        leaderBoard_label.pop()

        rank += 1

    leaderBoard_label.pop()

func add_message(message, from):
    var player
    var player_info

    if from == get_tree().get_network_unique_id():
        player_info = Client.player_info
    else:
        player = get_node_or_null("Players/" + str(from))

        if not player:
            return

        player_info = player.player_info

    chat_label.push_color(Color.yellow)
    chat_label.add_text(player_info["name"] + ": ")
    chat_label.pop()
    chat_label.add_text(message)
    chat_label.add_text("\n")

func _input(event):
    if event is InputEventKey and not event.is_echo() and event.is_pressed():
        if event.scancode == KEY_ENTER and chat_input.has_focus():
            var message = chat_input.get_text()

            if len(message) > 0:
                Server.rpc_id(1, "send_message", message)
                chat_input.set_text("")

            chat_input.release_focus()
        elif event.scancode == KEY_TAB:
            if not chat_input.has_focus():
                chat_input.call_deferred("grab_focus")
            else:
                chat_input.release_focus()
        elif event.scancode == KEY_ENTER and not chat_input.has_focus():
            chat_input.call_deferred("grab_focus")

func set_android(is_android):
    player.set_android(is_android)

    if not is_android:
        mobileLayout.visible = false
        chat.visible = true
    else:
        mobileLayout.visible = true
        chat.visible = false

func _on_FullscreenButton_pressed():
    OS.window_fullscreen = !OS.window_fullscreen

func _on_MoveJoystick_mouse_exited():
    if player.moveJoystick.is_dragging:
        player.is_shoot_pressable = false

func _on_ShootJoystick_mouse_exited():
    if player.moveJoystick.is_dragging:
        player.is_shoot_pressable = false

