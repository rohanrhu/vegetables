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

extends RigidBody2D

var is_me = true
var player_info: Dictionary

onready var game = $"/root/Game"
onready var camera = $"/root/Game/CameraContainer/Camera"
onready var character = $Characters/Tomato
onready var gameMenu = $"/root/Game/CanvasLayer/GameMenu"
onready var world = $"/root/Game/World"
onready var waterTileMap: TileMap = $"/root/Game/World/WaterTileMap"
onready var moveJoystick = $"/root/Game/CanvasLayer/MobileLayout/MoveJoystickUIC/MoveJoystick"
onready var shootJoystick = $"/root/Game/CanvasLayer/MobileLayout/ShootJoystickUIC/ShootJoystick"
onready var attackButton: TouchScreenButton = $"/root/Game/CanvasLayer/MobileLayout/AttackButtonUIC/AttackButton"
onready var useButton: TouchScreenButton = $"/root/Game/CanvasLayer/MobileLayout/UseButtonUIC/UseButton"
onready var inventory = $"/root/Game/CanvasLayer/Inventory"

var is_android = ScriptGlobals.is_android

export var default_speed: float = 20
export var compensation_speed: float = 20

var speed = default_speed
var direction = Vector2()
var server_position = Vector2.ZERO
var server_velocity = Vector2.ZERO

export var melee_attack_duration = 1250
export var melee_run_duration = 400

var is_melee_attacking = false
var is_melee_running = false
var melee_attack_time = 0
var melee_angle = 0

var is_shooting = false
var shoot_time = 0
var shoot_angle = 0

var current_weapon

var kills = 0

enum DIRECTIONS {
    LEFT,
    RIGHT,
    UP,
    DOWN
}

export var current_direction = DIRECTIONS.DOWN

var right = 0
var left = 0
var down = 0
var up = 0
var attack = false
var shoot = false
var aim := Vector2.ZERO
var velocity = Vector2.ZERO
var angle = 0

var input_right = 0
var input_left = 0
var input_down = 0
var input_up = 0
var input_attack = 0
var input_shoot = 0
var input_aim = 0
var input_angle = 0
var input_velocity = Vector2.ZERO

var is_shoot_pressable = true
var do_attack
var sync_time = 0

export var max_health = 100

var health = max_health

var rng = RandomNumberGenerator.new()

export var rpc_delay = 40
var rpc_time = 0
var is_remote_input = false
var last_input = false

var items = {0: 0}
var item = ScriptGlobals.ITEM.NONE

var shoot_shake_time = 0

func check_input_changed(input):
    if not last_input:
        last_input = input
        return true

    for i in range(len(input)):
        if i == ScriptGlobals.INPUT.AIM or i == ScriptGlobals.INPUT.ANGLE:
            continue

        if input[i] != last_input[i]:
            last_input = input
            return true

    return false

func _ready():
    Client.player = self

    moveJoystick.connect("controlling", self, "_joystick_input")
    moveJoystick.connect("released", self, "_joystick_input")

    shootJoystick.connect("controlling", self, "_joystick_input")
    shootJoystick.connect("released", self, "_joystick_input")

    if not ScriptGlobals.is_server and is_me:
        Server.rpc_id(1, "switch_weapon", ScriptGlobals.ITEM.NONE)

    add_collision_exception_with($Melee)
    set_health(health)

func switch_character(ch):
    $Characters/Tomato.visible = false
    $Characters/Pumpkin.visible = false
    $Characters/Watermelon.visible = false
    $Characters/Potato.visible = false

    if ch == ScriptGlobals.CHARACTER.TOMATO:
        character = $Characters/Tomato
    elif ch == ScriptGlobals.CHARACTER.WATERMELON:
        character = $Characters/Watermelon
    elif ch == ScriptGlobals.CHARACTER.PUMPKIN:
        character = $Characters/Pumpkin
    else:
        character = $Characters/Potato

    character.visible = true

func switch_weapon(item):
    if current_weapon and self.item == ScriptGlobals.ITEM.MEDIC:
        current_weapon.stop()

    $Weapons/AK47.visible = false
    $Weapons/Glock.visible = false
    $Weapons/Medic.visible = false

    self.item = item
    current_weapon = false

    if item == ScriptGlobals.ITEM.AK47:
        current_weapon = $Weapons/AK47
    elif item == ScriptGlobals.ITEM.GLOCK:
        current_weapon = $Weapons/Glock
    elif item == ScriptGlobals.ITEM.MEDIC:
        current_weapon = $Weapons/Medic

    if current_weapon:
        current_weapon.visible = true

    if is_me:
        inventory.set_current(item)

func increase_kills():
    kills += 1
    $"/root/Game/CanvasLayer/KillsInfo/KillsNumberLabel".text = str(kills)

func set_kills(num):
    kills = num
    $"/root/Game/CanvasLayer/KillsInfo/KillsNumberLabel".text = str(kills)

func bullet_hit(bullet, by):
    if not ScriptGlobals.is_server: return

    set_health(health - bullet.power)
    sync_health()

    if health <= 0:
        kill(by)
    else:
        sync_health()

func melee_hit(by):
    if not ScriptGlobals.is_server: return

    kill(by)

func kill(by):
    if by.player_info and by.player_info.has("id") and by.player_info["id"] == get_tree().get_network_unique_id():
        by.increase_kills()

    if current_weapon:
        current_weapon.stop()

    items = {0: 0}
    item = ScriptGlobals.ITEM.NONE
    inventory.clear()
    switch_weapon(item)

    if not ScriptGlobals.is_server:
        return

    set_health(max_health)
    sync_health()
    goto_random()

    var by_id = by.player_info["id"]

    Client.rpc("killed", player_info["id"], by_id)
    game.killed(player_info["id"], by_id)
    Server.kill(player_info["id"], by_id)

func set_health(h):
    health = h
    if health < 0:
        health = 0

    if not player_info.has("id"):
        game.set_health(health, max_health)

func set_ammo(item, ammo):
    items[item] = ammo
    var slot = inventory.get_slot_by_item(item)
    slot.set_ammo(ammo)

func sync_health():
    if not ScriptGlobals.is_server:
        return

    Client.rpc("sync_health", player_info["id"], health)

func goto_random():
    var born_area: Polygon2D = game.get_node("World/BornArea")

    rng.randomize()
    var x = rng.randf_range(born_area.polygon[0].x, born_area.polygon[1].x)
    rng.randomize()
    var y = rng.randf_range(born_area.polygon[0].y, born_area.polygon[3].y)

    global_position = Vector2(x, y)

func set_nickname(nickname):
    $Nickname/Label.text = nickname

func set_input(input):
    is_remote_input = true

    right = input[ScriptGlobals.INPUT.RIGHT]
    left = input[ScriptGlobals.INPUT.LEFT]
    down = input[ScriptGlobals.INPUT.DOWN]
    up = input[ScriptGlobals.INPUT.UP]
    attack = input[ScriptGlobals.INPUT.ATTACK]
    shoot = input[ScriptGlobals.INPUT.SHOOT]
    aim = input[ScriptGlobals.INPUT.AIM]
    velocity = input[ScriptGlobals.INPUT.VELOCITY]
    angle = input[ScriptGlobals.INPUT.ANGLE]

func _joystick_input():
    _input(false)

func _input(event):
    pass

func _process(delta):
    if ScriptGlobals.is_server and not is_me and (not player_info.has("id") or not (player_info["id"] in get_tree().get_network_connected_peers())):
        print("[Server] ", "Player#", player_info["id"], " is not exists. Freeing player object.")
        queue_free()
        return
    elif (not get_tree().get_network_peer()) or (get_tree().get_network_peer().get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_CONNECTED):
        get_tree().change_scene("res://scenes/MainMenu.tscn")
        return

    var current_time = OS.get_ticks_msec()
    var do_rpc = current_time - rpc_time > rpc_delay

    if not ScriptGlobals.is_server:
        if is_me and not gameMenu.is_opened and not is_remote_input and not ScriptGlobals.is_server:
            input_right = Input.get_action_strength("ui_right")
            input_left = Input.get_action_strength("ui_left")
            input_down = Input.get_action_strength("ui_down")
            input_up = Input.get_action_strength("ui_up")
            input_aim = world.get_global_mouse_position()

            if not is_android and \
            not moveJoystick.is_dragging and not moveJoystick.is_mouseover \
            and \
            not shootJoystick.is_dragging and not shootJoystick.is_mouseover \
            :
                pass
            else:
                input_shoot = current_weapon and items[item] > 0 and shootJoystick.is_trimming
                input_attack = attackButton.is_pressed()

            if not is_shoot_pressable and input_shoot:
                is_shoot_pressable = true
                input_shoot = false

            if is_android:
                input_velocity = moveJoystick.velocity

                left = velocity.x < 0
                right = velocity.x > 0
                up = velocity.y < 0
                down = velocity.y > 0
            else:
                input_velocity = Vector2.ZERO

            if is_android:
                if shootJoystick.is_dragging or moveJoystick.is_dragging:
                    if shootJoystick.is_dragging:
                        input_angle = -shootJoystick.angle

                        if input_angle < 0:
                            input_angle = PI + (PI - abs(input_angle))

                        input_angle = input_angle - PI
                    elif moveJoystick.is_dragging:
                        input_angle = -moveJoystick.angle

                        if input_angle < 0:
                            input_angle = PI + (PI - abs(input_angle))

                        input_angle = input_angle - PI

            aim = input_aim
            attack = input_attack
            shoot = input_shoot
            angle = input_angle
            velocity = input_velocity

            if input_shoot or input_attack or do_rpc:
                var input = {}
                input[ScriptGlobals.INPUT.RIGHT] = input_right
                input[ScriptGlobals.INPUT.LEFT] = input_left
                input[ScriptGlobals.INPUT.DOWN] = input_down
                input[ScriptGlobals.INPUT.UP] = input_up
                input[ScriptGlobals.INPUT.ATTACK] = input_attack
                input[ScriptGlobals.INPUT.SHOOT] = items[item] > 0 and input_shoot
                input[ScriptGlobals.INPUT.AIM] = input_aim
                input[ScriptGlobals.INPUT.VELOCITY] = input_velocity
                input[ScriptGlobals.INPUT.ANGLE] = input_angle

                if check_input_changed(input) or input_shoot or input_attack:
                    Server.rpc_id(1, "set_input", input)
                    Client.rpc("set_input", input, get_tree().get_network_unique_id())
                else:
                    Server.rpc_unreliable_id(1, "set_input", input)
                    Client.rpc_unreliable("set_input", input, get_tree().get_network_unique_id())

        if do_rpc:
            rpc_time = OS.get_ticks_msec()

    if do_rpc and player_info.has("id") and ScriptGlobals.is_server:
        Client.rpc_unreliable_id(player_info["id"], "set_position", global_position)
        Client.rpc_unreliable("set_position", global_position, player_info["id"])

    ($Sounds/Walking.stream as AudioStreamOGGVorbis).loop = false

    do_attack = false;

    if right:
        current_direction = DIRECTIONS.RIGHT
    elif left:
        current_direction = DIRECTIONS.LEFT
    elif down:
        current_direction = DIRECTIONS.DOWN
    elif up:
        current_direction = DIRECTIONS.UP

    if not is_android:
        velocity = Vector2(right - left, down - up)

    if attack and not is_melee_attacking:
        $Sounds/Walking.stop()
        $Sounds/Attack.stop()
        $Sounds/Attack.play()

        $Weapons.visible = false

        do_attack = true
        is_melee_attacking = true
        is_melee_running = true
        melee_attack_time = OS.get_ticks_msec()

        $Melee.shape_owner_set_disabled(0, false)

        speed = default_speed * 2

        if not is_android:
            var a = $Melee.global_position.x - aim.x
            var b = $Melee.global_position.y - aim.y
            var h = sqrt(pow(a, 2) + pow(b, 2))

            melee_angle = atan2(a, b)*-1
        else:
            melee_angle = self.angle

        $Melee.visible = true
        $Melee/Attack.frame = 0
        $Melee/Attack.play("attack")
    elif is_melee_attacking and (current_time - melee_attack_time) >= melee_attack_duration:
        is_melee_attacking = false
        melee_attack_time = 0

        $Melee.visible = false
        $Melee/Attack.stop()

    if is_melee_attacking and (current_time - melee_attack_time) >= melee_run_duration:
        is_melee_running = false
        speed = default_speed
        melee_angle = 0

        $Melee.shape_owner_set_disabled(0, true)
        $Weapons.visible = true

    if not is_melee_attacking:
        rotate_melee_to_mouse()

    var check_ammo

    if ScriptGlobals.is_server and not is_me:
        check_ammo = items[item] > 0
    elif not ScriptGlobals.is_server and is_me:
        check_ammo = items[item] > 0
    else:
        check_ammo = true

    if current_weapon and not is_melee_running and shoot and not is_shooting and check_ammo:
        var a = $Melee.global_position.x - aim.x
        var b = $Melee.global_position.y - aim.y
        var h = sqrt(pow(a, 2) + pow(b, 2))

        if not is_android:
            shoot_angle = atan2(a, b)*-1
            shoot_angle -= PI/2
        else:
            shoot_angle = self.angle - PI/2

        is_shooting = true
        shoot_time = OS.get_ticks_msec()

        current_weapon.shoot(shoot_angle)

        if item != ScriptGlobals.ITEM.MEDIC and (ScriptGlobals.is_server or is_me):
            items[item] -= 1
            if items[item] < 0:
                items[item] = 0

        if ScriptGlobals.is_server:
            Client.rpc_id(player_info["id"], "set_ammo", item, items[item])
    elif is_shooting and (not current_weapon or (current_time - shoot_time) >= current_weapon.shoot_duration):
        is_shooting = false
        shoot_time = 0
        shoot_angle = 0

    if is_me:
        if is_shooting and (current_time - shoot_shake_time > current_weapon.shake_delay):
            rng.randomize()
            shoot_shake_time = OS.get_ticks_msec()
            camera.addition = Vector2(
                rng.randi_range(-current_weapon.shake_power, current_weapon.shake_power),
                rng.randi_range(-current_weapon.shake_power, current_weapon.shake_power)
            )
        elif not is_shooting:
            shoot_shake_time = 0
            camera.addition = Vector2.ZERO

    rotate_weapon_to_mouse()

    if do_attack:
        if current_direction == DIRECTIONS.RIGHT:
            character.play("right_attack")
        elif current_direction == DIRECTIONS.LEFT:
            character.play("left_attack")
        elif current_direction == DIRECTIONS.DOWN:
            character.play("down_attack")
        elif current_direction == DIRECTIONS.UP:
            character.play("up_attack")
    elif do_attack:
        pass
    elif is_melee_attacking:
        pass
    elif right or input_right:
        if do_attack:
            pass
        else:
            character.play("right_walk")
    elif left or input_left:
        if do_attack:
            pass
        else:
            character.play("left_walk")
    elif down or input_down:
        if do_attack:
            pass
        elif character.playing:
            character.play("down_walk")
    elif up or input_up:
        if do_attack:
            pass
        else:
            character.play("up_walk")
    elif not is_melee_attacking and velocity == Vector2.ZERO:
        if current_direction == DIRECTIONS.RIGHT:
            character.play("right_idle")
        elif current_direction == DIRECTIONS.LEFT:
            character.play("left_idle")
        elif current_direction == DIRECTIONS.DOWN:
            character.play("down_idle")
        elif current_direction == DIRECTIONS.UP:
            character.play("up_idle")

    if (right or input_right or left or input_left or down or input_down or up or input_up) and not $Sounds/Walking.playing and not is_melee_running:
        $Sounds/Walking.play()

    if not is_melee_running:
        $Melee.visible = false

    if do_rpc:
        rpc_time = OS.get_ticks_msec()

func _physics_process(delta):
    if ScriptGlobals.is_server and not is_me and (not player_info.has("id") or not (player_info["id"] in get_tree().get_network_connected_peers())):
        print("[Server] ", "Player#", player_info["id"], " is not exists. Freeing player object.")
        queue_free()
        return
    elif not get_tree().get_network_peer() or (get_tree().get_network_peer().get_connection_status() != NetworkedMultiplayerPeer.CONNECTION_CONNECTED):
        get_tree().change_scene("res://scenes/MainMenu.tscn")
        return

    var v = velocity
    var velocity = v

    var current_time = OS.get_ticks_msec()

    if not ScriptGlobals.is_server:
        var da = abs(server_position.x - global_position.x)
        var db = abs(server_position.y - global_position.y)
        var dh = sqrt(pow(da, 2) + pow(db, 2))

        global_position = global_position.move_toward(server_position, delta*compensation_speed*dh)

        return

    if ScriptGlobals.is_server:
        if not is_android:
            velocity = Vector2(right - left, down - up)
    else:
        velocity = Vector2(input_right - input_left, input_down - input_up)

    if is_melee_running:
        var angle = melee_angle
        if angle < 0:
            angle = PI + (PI - abs(angle))

        angle = angle - (PI/2)

        velocity.x = cos(angle)
        velocity.y = sin(angle)
    else:
        if abs(velocity.x) == 1 and abs(velocity.y) == 1:
            velocity = velocity.normalized()

    if is_shooting and item != ScriptGlobals.ITEM.MEDIC:
        velocity *= speed/1.8
        velocity.x += cos(shoot_angle)*-1 * current_weapon.recoil
        velocity.y += sin(shoot_angle)*-1 * current_weapon.recoil

        velocity.x = clamp(velocity.x, -speed, speed)
        velocity.y = clamp(velocity.y, -speed, speed)
    elif velocity != Vector2.ZERO:
        velocity *= speed

    var tile_position = waterTileMap.world_to_map(global_position)
    var tile = waterTileMap.get_cellv(Vector2(tile_position.x, tile_position.y))

    if tile >= 0:
        velocity /= 2

    apply_central_impulse(velocity)

    is_remote_input = false

func rotate_melee_to_mouse():
    var angle

    if not is_android:
        var a = $Melee.global_position.x - aim.x
        var b = $Melee.global_position.y - aim.y
        var h = sqrt(pow(a, 2) + pow(b, 2))
        angle = atan2(a, b)*-1
    else:
        angle = self.angle

    $Melee.rotation = angle

func rotate_weapon_to_mouse():
    var angle

    if not is_android:
        var a = $Melee.global_position.x - aim.x
        var b = $Melee.global_position.y - aim.y
        var h = sqrt(pow(a, 2) + pow(b, 2))
        angle = atan2(a, b)*-1
    else:
        angle = self.angle

    $Weapons.rotation = angle

func set_android(is_android):
    self.is_android = is_android
    Server.rpc_id(1, "set_android", is_android)

func _unhandled_input(event):
    if not is_me:
        return

    if event is InputEventMouseButton:
        if event.button_index == BUTTON_LEFT:
            input_shoot = int(current_weapon and items[item] > 0 and event.is_pressed())
        elif event.button_index == BUTTON_RIGHT:
            input_attack = int(event.is_pressed())
    elif event is InputEventKey and not event.is_echo() and event.is_pressed():
        if event.scancode == KEY_1:
            inventory.slots[0].switch()
        elif event.scancode == KEY_2:
            inventory.slots[1].switch()
        elif event.scancode == KEY_3:
            inventory.slots[2].switch()

func _on_Medic_complete():
    items[item] -= 1

    if ScriptGlobals.is_server:
        Client.rpc_id(player_info["id"], "set_ammo", item, items[item])
        set_health(100)
        sync_health()
