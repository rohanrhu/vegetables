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

extends KinematicBody2D

onready var player = get_parent()

func _ready():
    pass

func _physics_process(delta):
    var collision: KinematicCollision2D = move_and_collide(Vector2.ZERO, false, true, true)

    if collision:
        player.is_melee_running = false
        player.speed = player.default_speed
        player.melee_angle = 0

        player.get_node("Weapons").visible = true

        shape_owner_set_disabled(0, true)

        if collision.collider is ScriptGlobals.Player:
            collision.collider.melee_hit(player)
