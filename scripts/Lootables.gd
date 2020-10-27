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

extends Node2D

onready var nRandomArea = $"/root/Game/World/BornArea"
onready var nLootBox = $LootBox
onready var nLootBoxes = $LootBoxes

export var number = 30

var id_i = 0
var rng = RandomNumberGenerator.new()
var boxes = []

func _ready():
    nLootBox.visible = false
    nLootBox.find_node("Tooltip").visible = false

    if ScriptGlobals.is_server:
        for i in range(number):
            add_loot_box()

func add_loot_box(id=0, position=null, item=0, ammo=-1):
    var box = nLootBox.duplicate()
    if id == 0:
        id_i += 1
        box.id = id_i
    else:
        box.id = id
    box.name = str(box.id)
    box.visible = true
    if ammo > -1:
        box.ammo = ammo
    if item > 0:
        box.item = item

    if position == null:
        box.global_position = random_position()
    else:
        box.global_position = position

    boxes.append(box)
    nLootBoxes.add_child(box)

    if ScriptGlobals.is_server:
        Client.rpc("add_loot_box", box.id, box.global_position, box.item, box.ammo)

    return box

func remove_loot_box(box):
    boxes.erase(box)
    box.destroy()
    box.queue_free()

    if ScriptGlobals.is_server:
        add_loot_box()

func random_position():
    var born_area: Polygon2D = nRandomArea

    rng.randomize()
    var x = rng.randf_range(born_area.polygon[0].x, born_area.polygon[1].x)
    rng.randomize()
    var y = rng.randf_range(born_area.polygon[0].y, born_area.polygon[3].y)

    return Vector2(x, y)
