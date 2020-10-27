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

extends StaticBody2D

onready var nPlayer = $"/root/Game/Player"
onready var nInventory = $"/root/Game/CanvasLayer/Inventory"
onready var nLootables = $"/root/Game/Lootables"
onready var nTooltip = $Tooltip
onready var nBoxSprite = $BoxSprite

export var ammo_min = 10
export var ammo_max = 30

var id = 0
var is_interactable = false
var is_destroyed = false
var item = 0
var ammo = 0

var rng = RandomNumberGenerator.new()

func _ready():
    if ScriptGlobals.is_server:
        rng.randomize()
        item = rng.randi_range(1, len(ScriptGlobals.ITEM)-1)
        rng.randomize()
        if item == ScriptGlobals.ITEM.MEDIC:
            ammo = 1
        else:
            ammo = rng.randi_range(ammo_min, ammo_max)

    nTooltip.visible = false

    nPlayer.useButton.connect("pressed", self, "_on_UseButton_pressed")

func _unhandled_key_input(event):
    if ScriptGlobals.is_server:
        return

    if is_interactable and event.pressed and not event.echo and event.scancode == KEY_E:
        if not is_destroyed:
            Server.rpc_id(1, "destroy_loot_box", id)
        else:
            Server.rpc_id(1, "loot_loot_box", id)

func destroy():
    $Weapons/AK47.visible = false
    $Weapons/Glock.visible = false
    $Weapons/Medic.visible = false

    if item == ScriptGlobals.ITEM.GLOCK:
        $Weapons/Glock.visible = true
    elif item == ScriptGlobals.ITEM.AK47:
        $Weapons/AK47.visible = true
    elif item == ScriptGlobals.ITEM.MEDIC:
        $Weapons/Medic.visible = true

    $Weapons.visible = true
    $Tooltip/Label.text = "Press E to loot"

    is_destroyed = true
    nBoxSprite.visible = false
    shape_owner_set_disabled(0, true)

func loot(player):
    if player.items.has(item):
        player.items[item] += ammo
    else:
        player.items[item] = ammo

    nLootables.remove_loot_box(self)

    if not ScriptGlobals.is_server and player.is_me:
        nInventory.add_item(item, ammo)

func _on_InteractArea_body_entered(body):
    if ScriptGlobals.is_server:
        is_interactable = true
        nTooltip.visible = true

        return

    if body.name != "Player" or !body.is_me:
        return

    is_interactable = true
    nTooltip.visible = true

func _on_InteractArea_body_exited(body):
    if ScriptGlobals.is_server:
        is_interactable = false
        nTooltip.visible = false

        return

    if body.name != "Player" or !body.is_me:
        return

    is_interactable = false
    nTooltip.visible = false

func _on_UseButton_pressed():
    if ScriptGlobals.is_server:
        return

    if not is_interactable:
        return

    if not is_destroyed:
        Server.rpc_id(1, "destroy_loot_box", id)
    else:
        Server.rpc_id(1, "loot_loot_box", id)
