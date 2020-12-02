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

extends TouchScreenButton

onready var nPlayer = $"/root/Game/Player"
onready var nAK47 = $AK47
onready var nGlock = $Glock
onready var nMedic = $Medic
onready var nAmmoLabel = $AmmoLabel

var is_readonly = false
var item = ScriptGlobals.ITEM.NONE
var ammo = 0

func _ready():
    self.connect("pressed", self, "_on_pressed")

    nAK47.visible = false
    nGlock.visible = false
    nMedic.visible = false

func set_item(item, ammo=0):
    nAK47.visible = false
    nGlock.visible = false
    nMedic.visible = false

    if item == ScriptGlobals.ITEM.AK47:
        nAK47.visible = true
    elif item == ScriptGlobals.ITEM.GLOCK:
        nGlock.visible = true
    elif item == ScriptGlobals.ITEM.MEDIC:
        nMedic.visible = true

    self.item = item
    self.ammo = ammo
    $AmmoLabel.text = str(self.ammo)

func set_ammo(ammo):
    self.ammo = ammo
    $AmmoLabel.text = str(self.ammo)

func add_ammo(ammo):
    self.ammo += ammo
    $AmmoLabel.text = str(self.ammo)

func _on_pressed():
    switch()

func switch():
    Server.rpc_id(1, "switch_weapon", item)

func clear():
    set_item(ScriptGlobals.ITEM.NONE)
