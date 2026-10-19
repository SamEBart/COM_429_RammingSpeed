extends Node

const _Log = preload("res://scripts/turn/game_log.gd")

func archerFire(ship: Ship):
	if ship.getArchers() and ship._enemyTarget:
		var target = ship._enemyTarget
		var archers = ship.getArchers()
		_Log.push("Ship: %s attacks: %s" % [ship.name, ship._enemyTarget.name])
		for i in archers.size():
			if randi_range(1, 6) == 6:
				match randi_range(2, 12):
					#Engineer Killed
					2:
						if target.getEngineers():
							Global.addToDead(target, target.getEngineers())
					
					#Deck Crew Killed
					3,9,10,11:
						if target.getDeckCrew():
							Global.addToDead(target, target.getDeckCrew())
					
					#Random Marine Killed
					4,5:
						match randi_range(1, 3):
							1:
								if target.getArchers():
									Global.addToDead(target, target.getArchers())
							2:
								if target.getJavelineers():
									Global.addToDead(target, target.getJavelineers())
							3:
								if target.getSoldiers():
									Global.addToDead(target, target.getSoldiers())
					
					#Rower Killed
					6,7,8:
						if target.getReserveRowers():
							Global.addToDead(target, target.getReserveRowers())
						elif target.getActiveRowers():
							Global.addToDead(target, target.getActiveRowers())

func ballistaFire(ship: Ship):
	if ship._ballista and ship._enemyTarget:
		var target = ship._enemyTarget
		var temp = true
		while temp:
			if randi_range(1, 4) <= ship._ballistaTargetRange:
				match randi_range(2, 12):
					#Engineer Killed
					2:
						if target.getEngineers():
							temp = false
							Global.addToDead(target, target.getEngineers())
					
					#Deck Crew Killed
					3,9,10,11:
						if target.getDeckCrew():
							temp = false
							Global.addToDead(target, target.getDeckCrew())
					
					#Random Marine Killed
					4,5:
						match randi_range(1, 3):
							1:
								if target.getArchers():
									temp = false
									Global.addToDead(target, target.getArchers())
							2:
								if target.getJavelineers():
									temp = false
									Global.addToDead(target, target.getJavelineers())
							3:
								if target.getSoldiers():
									temp = false
									Global.addToDead(target, target.getSoldiers())
					
					#Rower Killed
					6,7,8:
						if target.getReserveRowers():
							temp = false
							Global.addToDead(target, target.getReserveRowers())
						elif target.getActiveRowers():
							temp = false
							Global.addToDead(target, target.getActiveRowers())

func catapultFire(ship: Ship):
	if ship._catapult and ship._enemyTarget:
		var target = ship._enemyTarget
		#ASSUMING 1-6 with range and same range application as it is not stated
		if randi_range(1, 6) <= ship._catapultTargetRange:
			match randi_range(2, 12):
				#Engineer Killed
				2:
					if target.getEngineers():
						Global.addToDead(target, target.getEngineers())
				
				#Deck Crew Killed (2)
				3:
					for i in 2:
						if target.getDeckCrew():
							Global.addToDead(target, target.getDeckCrew())
				
				#Random Marine Killed
				4,5:
					match randi_range(1, 3):
						1:
							if target.getArchers():
								Global.addToDead(target, target.getArchers())
						2:
							if target.getJavelineers():
								Global.addToDead(target, target.getJavelineers())
						3:
							if target.getSoldiers():
								Global.addToDead(target, target.getSoldiers())
				
				#Rower Killed (2)
				6,8:
					for i in 2:
						if target.getReserveRowers():
							Global.addToDead(target, target.getReserveRowers())
						elif target.getActiveRowers():
							Global.addToDead(target, target.getActiveRowers())
				
				#Rower Killed
				7:
					if target.getReserveRowers():
						Global.addToDead(target, target.getReserveRowers())
					elif target.getActiveRowers():
						Global.addToDead(target, target.getActiveRowers())
				
				#Deck Crew Killed
				9,10,11:
					if target.getDeckCrew():
						Global.addToDead(target, target.getDeckCrew())
