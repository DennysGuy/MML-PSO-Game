class_name Entity extends CharacterBody3D


@export var state_machine : StateMachine
@export var model: Node3D

@export_group("Entity Stats")
@export var move_speed : float = 8.0
@export var acceleration : float = 20.0
@export var deceleration : float = 120.0
@export var rotation_speed : float = 12.0
@export var jump_impulse : float = 12.0
@export var gravity : float = -30.0

@export_group("Entity Animation")
@export var animation_player : AnimationPlayer
