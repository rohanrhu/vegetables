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

extends Node

const Player = preload("res://scripts/Player.gd")

var player = false
var player_info: Dictionary
var peer: WebSocketClient

var me: Player

func _ready():
    get_tree().connect("connected_to_server", self, "_on_server_connected")
    get_tree().connect("connection_failed", self, "_on_server_failed")

func _process(delta):
    if not peer:
        return

    if peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED \
       || \
       peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING \
    :
        peer.poll();

func join_game():
    peer = WebSocketClient.new()
    peer.connect("connection_closed", self, "_on_connection_closed")
    peer.connect("connection_error", self, "_on_connection_error")
    peer.connect("server_disconnected", self, "_on_connection_closed")

    if type_exists("X509Certificate"):
        var cer = X509Certificate.new()
        if cer:
            cer.load(ScriptGlobals.SSL_CER_PATH)
            peer.set_trusted_ssl_certificate(cer)
            peer.set_verify_ssl_enabled(false)

    var url

    if not OS.is_debug_build():
        url = "wss://"+ScriptGlobals.SERVER_ADDRESS + ":" + str(ScriptGlobals.SERVER_PORT)
    else:
        if not ScriptGlobals.is_android:
            url = "ws://127.0.0.1:" + str(ScriptGlobals.SERVER_PORT)
        else:
            url = "ws://192.168.1.103:" + str(ScriptGlobals.SERVER_PORT)

    if peer.connect_to_url(url, PoolStringArray(), true) != OK:
        print("Client error.")

    get_tree().set_network_peer(peer)

func _on_connection_closed(was_clean_close):
    get_tree().change_scene("res://scenes/MainMenu.tscn")

func _on_connection_error():
    get_tree().change_scene("res://scenes/MainMenu.tscn")

func _on_server_connected():
    pass

func _on_server_failed():
    get_tree().change_scene("res://scenes/MainMenu.tscn")

remote func set_position(position: Vector2, id=false):
    var player

    if not id:
        player = get_node_or_null("/root/Game/Player")
        if not player:
            return
    else:
        player = get_node_or_null("/root/Game/Players/"+str(id))

    if not player:
        return

    player.server_position = position

remote func set_velocity(velocity: Vector2, id=false):
    var player

    if not id:
        player = get_node_or_null("/root/Game/Player")
        if not player:
            return
    else:
        player = get_node_or_null("/root/Game/Players/"+str(id))

    if not player:
        return

    player.server_velocity = velocity

remote func set_input(input, id):
    if ScriptGlobals.is_server:
        return

    var player

    if id != 1:
        player = get_node_or_null("/root/Game/Players/"+str(id))

    if not player:
        return

    player.set_input(input)

remote func new_player(player_info):
    if player_info["id"] == get_tree().get_network_unique_id():
        self.player_info["character"] = player_info["character"]
        $"/root/Game/Player".switch_character(player_info["character"])
        return

    var game = $"/root/Game"
    var players = game.find_node("Players")

    var player = game.create_player()
    player.player_info = player_info
    if player_info.has("is_android"):
        player.is_android = player_info["is_android"]

    player.set_name(str(player_info["id"]))
    player.set_nickname(player_info["name"])
    player.switch_character(player_info["character"])
    player.switch_weapon(player_info["item"])

remote func set_players(players):
    for _player in players:
        if _player["id"] == get_tree().get_network_unique_id():
            continue

        new_player(_player)

remote func player_exit(id):
    var player = get_node_or_null("/root/Game/Players/"+str(id))

    if not player:
        return

    player.queue_free()

remote func killed(id, by):
    if get_tree().get_rpc_sender_id() != 1:
        return

    $"/root/Game".killed(id, by)

remote func sync_health(id, health):
    var player

    if id == get_tree().get_network_unique_id():
        player = get_node_or_null("/root/Game/Player")
    else:
        player = get_node_or_null("/root/Game/Players" + str(id))

    if not player:
        return

    player.set_health(health)

remote func set_bloods(blood_positions):
    var blood_proto = $"/root/Game/Blood"
    var blood

    for pos in blood_positions:
        blood = blood_proto.duplicate()
        blood.global_position.x = pos[0]
        blood.global_position.y = pos[1]
        blood.rotation = pos[2]
        blood.visible = true

        $"/root/Game/Bloods".add_child(blood)

        blood.place()

remote func set_leaderboard(leaders):
    $"/root/Game".set_leaderboard(leaders)

remote func send_message(message, from):
    if get_tree().get_rpc_sender_id() != 1:
        return

    $"/root/Game".add_message(message, from)

remote func set_android(id, is_android):
    var player = get_node_or_null("/root/Game/Players" + str(id))

    if not player:
        return

    player.is_android = is_android

remote func joined():
    $"/root/Game".set_android(ScriptGlobals.is_android)

remote func set_loot_boxes(boxes):
    for box in boxes:
        add_loot_box(box[0], box[1], box[2], box[3])

remote func add_loot_box(id, position, item, ammo):
    var nLootables = $"/root/Game/Lootables"
    nLootables.add_loot_box(id, position, item, ammo)

remote func destroy_loot_box(id):
    if ScriptGlobals.is_server:
        return

    var box = get_node("/root/Game/Lootables/LootBoxes/"+str(id))
    box.destroy()

remote func loot_loot_box(id, player_id):
    var player

    if player_id == get_tree().get_network_unique_id():
        player = $"/root/Game/Player"
    else:
        player = get_node_or_null("/root/Game/Players/" + str(player_id))

    var box = get_node_or_null("/root/Game/Lootables/LootBoxes/"+str(id))

    box.loot(player)

remote func switch_weapon(item, player_id):
    var player

    if player_id == get_tree().get_network_unique_id():
        player = $"/root/Game/Player"
    else:
        player = get_node_or_null("/root/Game/Players/" + str(player_id))

    if not player:
        return

    player.switch_weapon(item)

remote func set_ammo(item, ammo):
    if not player:
        player = $"/root/Game/Player"
    player.set_ammo(item, ammo)
