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

export var is_auto = false
export var shoot_duration = 125
export var recoil = 50
export var bullets = 0
export var shake_power = 50
export var shake_delay = 25

onready var nGame = $"/root/Game"
onready var nPlayer = get_node("../../")
onready var nBullet = get_node_or_null("Bullet")
onready var nBullets = $Bullets
onready var nSprite = $Sprite
onready var nSounds_Shot = $Sounds/Shoot

export var item = 0

var is_shooting = false
var shoot_time = 0

signal complete

func _ready():
    pass

func _process(delta):
    var current_time = OS.get_ticks_msec()

    if is_shooting and (current_time - shoot_time >= shoot_duration):
        is_shooting = false
        nSprite.stop()
        nSprite.play("idle")
        nSounds_Shot.stop()

        emit_signal("complete")

func shoot(angle):
    shoot_time = OS.get_ticks_msec()
    is_shooting = true

    if item != ScriptGlobals.ITEM.MEDIC:
        nSprite.stop()
        nSprite.play("shoot")
        nSounds_Shot.play()
    else:
        if nSprite.animation != "shoot":
            nSprite.stop()
        nSprite.play("shoot")
        if not nSounds_Shot.is_playing():
            nSounds_Shot.play()

    if item == ScriptGlobals.ITEM.MEDIC:
        return

    var bullet = nBullet.duplicate()
    nGame.add_child(bullet)
    bullet.player = nPlayer
    bullet.global_position = nBullet.global_position
    bullet.global_rotation = nBullet.global_rotation
    bullet.angle = angle
    bullet.visible = true
    bullet.shape_owner_set_disabled(0, false)
    bullet.shoot()

func stop():
    is_shooting = false
    nSounds_Shot.stop()
    nSprite.stop()
    nSprite.play("idle")

func _on_Sprite_animation_finished():
    if item == ScriptGlobals.ITEM.MEDIC:
        return

    if nSprite.animation == "shoot":
        nSprite.play("idle")
