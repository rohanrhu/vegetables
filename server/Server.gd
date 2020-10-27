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

const Game = preload("res://scripts/Game.gd")
const Player = preload("res://scripts/Player.gd")

var server: WebSocketServer
var players = {}
var game: Game

var character_i = -1

func _ready():
    pass

func _process(delta):
    if not ScriptGlobals.is_server:
        return

    var peer

    for id in get_tree().get_network_connected_peers():
        peer = server.get_peer(id)

        if not peer.is_connected_to_host():
            peer.close()

    if not server:
        return

    if server.is_listening():
        server.poll();

func serve():
    print("[Server] ", "create_server()")

    get_tree().connect("network_peer_connected", self, "_on_player_connected")
    get_tree().connect("network_peer_disconnected", self, "_on_player_disconnected")

    server = WebSocketServer.new()

    if "--ssl" in OS.get_cmdline_args():
        var key_path = ScriptGlobals.SSL_KEY_PATH
        var cer_path = ScriptGlobals.SSL_CER_PATH
        var chain_path = ScriptGlobals.SSL_FULLCHAIN_PATH

        var key = CryptoKey.new()
        var cer = X509Certificate.new()
        var chain = X509Certificate.new()

        key.load(key_path)
        cer.load(cer_path)
        chain.load(chain_path)

        server.set_private_key(key)
        server.set_ssl_certificate(cer)
        server.set_ca_chain(chain)

    if server.has_method("set_extra_headers"):
        server.set_extra_headers(["Access-Control-Allow-Origin: v6p9d9t4.ssl.hwcdn.net"])

    if server.listen(ScriptGlobals.SERVER_PORT, PoolStringArray(), true) != OK:
        print("[Server] Could not start the server.")
        return
    else:
        print("[Server] Server is listening on 0.0.0.0:%s." % ScriptGlobals.SERVER_PORT)

    get_tree().set_network_peer(server)
    get_tree().change_scene("res://scenes/Game.tscn")

func _on_player_connected(id):
    print("[Server] Player connected: #"+str(id))

    character_i += 1

    if character_i == ScriptGlobals.CHARACTER.size()-1:
        character_i = 0

    players[id] = {
        id = id,
        name = "Player"+str(id),
        character = ScriptGlobals.CHARACTER.values()[character_i],
        kills = 0
    }

func _on_player_disconnected(id):
    print("[Server] Player disconnected: #"+str(id))
    if players.has(id):
        if players[id].has("player") and players[id]["player"]:
            players[id]["player"].queue_free()
        players.erase(id)

    Client.rpc("player_exit", id)
    Client.rpc("set_leaderboard", get_leaderboard())

remote func set_player_name(name):
    players[get_tree().get_rpc_sender_id()]["name"] = name

remote func join_game():
    game = $"/root/Game"

    var player: Player = game.create_player()
    player.goto_random()
    player.set_name(str(get_tree().get_rpc_sender_id()))
    player.player_info = {
        id = get_tree().get_rpc_sender_id(),
        name = players[get_tree().get_rpc_sender_id()]["name"],
        character = players[get_tree().get_rpc_sender_id()]["character"],
        item = ScriptGlobals.ITEM.NONE
    }
    players[get_tree().get_rpc_sender_id()]["player"] = player
    player.global_position = Vector2(player.global_position.x+50, player.global_position.y+50)

    Client.rpc("new_player", player.player_info)
    Client.rpc_id(get_tree().get_rpc_sender_id(), "joined")

remote func set_input(input):
    var id = get_tree().get_rpc_sender_id()
    players[id]["player"].set_input(input)

remote func sync_position():
    if not players.has(get_tree().get_rpc_sender_id()):
        return

    var player_info = players[get_tree().get_rpc_sender_id()]
    var player = player_info["player"]

    Client.rpc_unreliable_id(get_tree().get_rpc_sender_id(), "set_position", player.global_position)
    Client.rpc_unreliable("set_position", player.global_position, get_tree().get_rpc_sender_id())

remote func sync_players():
    var opponents = []
    for _id in players:
        opponents.append({
            id = players[_id]["id"],
            name = players[_id]["name"],
            character = players[_id]["character"],
            health = 100,
            is_android = players[_id]["player"].is_android,
            item = players[_id]["player"].item
        })

    Client.rpc_id(get_tree().get_rpc_sender_id(), "set_players", opponents)
    Client.rpc("set_leaderboard", get_leaderboard())

remote func sync_bloods():
    var blood_positions = []

    for blood in $"/root/Game/Bloods".get_children():
        blood_positions.append([blood.global_position.x, blood.global_position.y, blood.rotation])

    Client.rpc_id(get_tree().get_rpc_sender_id(), "set_bloods", blood_positions)

remote func sync_loot_boxes():
    var boxes = []

    for box in $"/root/Game/Lootables".boxes:
        boxes.append([box.id, box.global_position, box.item, box.ammo])

    Client.rpc_id(get_tree().get_rpc_sender_id(), "set_loot_boxes", boxes)

func get_leaderboard(length=10):
    var leaders = []

    var sorted = players.values()
    sorted.sort_custom(self, "_leaderboard_sortf")

    var i = 0
    for leader in sorted:
        if i == length: return
        leaders.append([leader["id"], leader["kills"]])
        i += 1

    return leaders

func _leaderboard_sortf(a, b):
    return a["kills"] > b["kills"]

func kill(id, by):
    players[id]["kills"] = 0
    players[by]["kills"] += 1
    Client.rpc("set_leaderboard", get_leaderboard())

remote func send_message(message):
    Client.rpc("send_message", message, get_tree().get_rpc_sender_id())

remote func set_android(is_android):
    players[get_tree().get_rpc_sender_id()]["player"].is_android = is_android
    Client.rpc("set_android", get_tree().get_rpc_sender_id(), is_android)

remote func destroy_loot_box(id):
    var box = get_node("/root/Game/Lootables/LootBoxes/"+str(id))
    box.destroy()

    Client.rpc("destroy_loot_box", id)

remote func loot_loot_box(id):
    var player = get_node_or_null("/root/Game/Players/" + str(get_tree().get_rpc_sender_id()))
    if not player: return

    var box = get_node_or_null("/root/Game/Lootables/LootBoxes/"+str(id))
    if not box:
        return

    box.loot(player)

    Client.rpc("loot_loot_box", id, player.player_info["id"])

remote func switch_weapon(item):
    var player = get_node_or_null("/root/Game/Players/" + str(get_tree().get_rpc_sender_id()))
    if not player: return

    player.switch_weapon(item)
    Client.rpc("switch_weapon", item, player.player_info["id"])
