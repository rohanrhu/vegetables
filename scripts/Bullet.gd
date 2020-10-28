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

extends KinematicBody2D

export var shoot_duration = 1000
export var speed = 1
export var mass = 20
export var power = 10

var player
var is_shooting = false
var shoot_time = 0
var angle = 0

func _ready():
    pass

func _physics_process(delta):
    if not is_shooting:
        return

    var current_time = OS.get_system_time_msecs()

    if current_time - shoot_time >= shoot_duration:
        queue_free()

    var velocity = Vector2()
    velocity.x = cos(angle)
    velocity.y = sin(angle)

    var collision: KinematicCollision2D = move_and_collide(velocity * speed, false)

    if collision:
        if collision.collider is RigidBody2D:
            collision.collider.apply_central_impulse(-collision.normal * mass)

        if collision.collider is ScriptGlobals.Player:
            collision.collider.bullet_hit(self, player)

        queue_free()

func shoot():
    is_shooting = true
    shoot_time = OS.get_system_time_msecs()
