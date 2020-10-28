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

onready var is_android = not is_server and OS.get_name() == "Android"

const Player = preload("res://scripts/Player.gd")
const Bullet = preload("res://scripts/Bullet.gd")

const VERSION = [1, 0, ""]
const VERSION_STRING = "v1.0"

const SERVER_ADDRESS = 'SERVER_ADDRESS'
const SERVER_PORT = 2095
const MAX_PLAYERS = 50

const SSL_KEY_PATH = "KEY_PATH"
const SSL_CER_PATH = "CER_PATH"
const SSL_FULLCHAIN_PATH = "FULLCHAIN_PATH"

var is_server = false

enum INPUT {
    RIGHT,
    LEFT,
    DOWN,
    UP,
    ATTACK,
    SHOOT,
    AIM,
    VELOCITY,
    ANGLE
}

enum CHARACTER {
    TOMATO,
    PUMPKIN,
    WATERMELON,
    POTATO
}

enum LOOT_BOX {
    ID,
    POSITON,
    ITEM,
    AMMO
}

enum ITEM {
    NONE,
    GLOCK,
    AK47,
    MEDIC
}
