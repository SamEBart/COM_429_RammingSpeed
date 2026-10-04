extends Node

func archerFire(ship: Ship):
	if ship.getArchers() and ship._enemyTarget:
		var target = ship._enemyTarget
		var archers = ship.getArchers()
		for i in archers.size():
			if randi_range(1, 6) == 6:
				match randi_range(2, 12):
					#Engineer Killed
					2:
						if target.getEngineers():
							var deadGuys = target.getEngineers()
							target.kill(deadGuys.pick_random())
					
					#Deck Crew Killed
					3,9,10,11:
						if target.getDeckCrew():
							var deadGuys = target.getDeckCrew()
							target.kill(deadGuys.pick_random())
					
					#Random Marine Killed
					4,5:
						if target.getMarines():
							var deadGuys = target.getMarines()
							target.kill(deadGuys.pick_random())
					
					#Rower Killed
					6,7,8:
						if target.getReserveRowers():
							var deadGuys = target.getReserveRowers()
							target.kill(deadGuys.pick_random())
						elif target.getActiveRowers():
							var deadGuys = target.getActiveRowers()
							target.kill(deadGuys.pick_random())
					
