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

extends Control

export var number = 3
export var margin = 10

onready var nPlayer = $"/root/Game/Player"
onready var nSlotProto = $SlotProto
onready var nSlots = $Slots

var slots = []
var current = false

func _ready():
    nSlotProto.visible = false
    set_slots(number)

func set_slots(number):
    for i in range(number):
        var slot: TouchScreenButton = nSlotProto.duplicate()
        slot.visible = true
        slot.set_name(str(i))

        slot.get_node("AK47").visible = false
        slot.get_node("Glock").visible = false

        nSlots.add_child(slot)

        slots.append(slot)

        slot.global_position.x += i * (slot.normal.get_size().x + margin)

    current = slots[0]

func get_slot_by_item(item):
    for slot in slots:
        if slot.item == item:
            return slot

    return false

func add_item(item, ammo=0):
    var switch = not current or current.item == ScriptGlobals.ITEM.NONE
    var slot = get_slot_by_item(item)

    if not slot:
        slot = get_slot_by_item(ScriptGlobals.ITEM.NONE)

    if not slot:
        slot = current

    if slot.item == item:
        slot.add_ammo(ammo)
    else:
        slot.set_item(item, ammo)

    if switch:
        slot.switch()

func set_current(item):
    var slot = get_slot_by_item(item)

    if not slot:
        return false

    for _slot in slots:
        if _slot.item == item:
            current = _slot
            return _slot

    return false

func clear():
    for slot in slots:
        slot.clear()
