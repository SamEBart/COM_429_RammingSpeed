extends Node2D
class_name Person

var can_boarding_action : bool
var act_as_auxiliary = false
var is_alive = true
var used = false

func chnage_boarding_participation(answer : bool):
	can_boarding_action = answer

func change_auxiliary_status(answer : bool):
	act_as_auxiliary = answer

func change_alive_status(answer : bool):
	is_alive = answer
