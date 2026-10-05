extends Node

func archerFire(ship: Ship):
	if ship.getArchers() and ship._enemyTarget:
		var target = ship._enemyTarget
		var archers = ship.getArchers()
		for i in archers.size():
			if randi_range(1, 6) == 6:
				print("Archers Before: ", target.name, ", E: ", target.getEngineers().size(), " , DC: ",
				target.getDeckCrew().size(), ", M: ",
				target.getArchers().size() + target.getJavelineers().size() + target.getSoldiers().size(),
				", RR: ", target.getReserveRowers().size(), ", AR: ", target.getActiveRowers().size())
				
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
						match randi_range(1, 3):
							1:
								if target.getArchers():
									var deadGuys = target.getArchers()
									target.kill(deadGuys.pick_random())
							2:
								if target.getJavelineers():
									var deadGuys = target.getJavelineers()
									target.kill(deadGuys.pick_random())
							3:
								if target.getSoldiers():
									var deadGuys = target.getSoldiers()
									target.kill(deadGuys.pick_random())
					
					#Rower Killed
					6,7,8:
						if target.getReserveRowers():
							var deadGuys = target.getReserveRowers()
							target.kill(deadGuys.pick_random())
						elif target.getActiveRowers():
							var deadGuys = target.getActiveRowers()
							target.kill(deadGuys.pick_random())
				
				print("Archers After: ", target.name, ", E: ", target.getEngineers().size(), " , DC: ",
				target.getDeckCrew().size(), ", M: ",
				target.getArchers().size() + target.getJavelineers().size() + target.getSoldiers().size(),
				", RR: ", target.getReserveRowers().size(), ", AR: ", target.getActiveRowers().size())
				print("==================================")

func ballistaFire(ship: Ship):
	if ship._ballista and ship._enemyTarget:
		var target = ship._enemyTarget
		var temp = true
		while temp:
			if randi_range(1, 4) == 4:
				#DO RANGE PART LATER ^^^
				print("Ballista Before: ", target.name, ", E: ", target.getEngineers().size(), " , DC: ",
				target.getDeckCrew().size(), ", M: ",
				target.getArchers().size() + target.getJavelineers().size() + target.getSoldiers().size(),
				", RR: ", target.getReserveRowers().size(), ", AR: ", target.getActiveRowers().size())
				
				match randi_range(2, 12):
					#Engineer Killed
					2:
						if target.getEngineers():
							temp = false
							var deadGuys = target.getEngineers()
							target.kill(deadGuys.pick_random())
					
					#Deck Crew Killed
					3,9,10,11:
						if target.getDeckCrew():
							temp = false
							var deadGuys = target.getDeckCrew()
							target.kill(deadGuys.pick_random())
					
					#Random Marine Killed
					4,5:
						match randi_range(1, 3):
							1:
								if target.getArchers():
									temp = false
									var deadGuys = target.getArchers()
									target.kill(deadGuys.pick_random())
							2:
								if target.getJavelineers():
									temp = false
									var deadGuys = target.getJavelineers()
									target.kill(deadGuys.pick_random())
							3:
								if target.getSoldiers():
									temp = false
									var deadGuys = target.getSoldiers()
									target.kill(deadGuys.pick_random())
					
					#Rower Killed
					6,7,8:
						if target.getReserveRowers():
							temp = false
							var deadGuys = target.getReserveRowers()
							target.kill(deadGuys.pick_random())
						elif target.getActiveRowers():
							temp = false
							var deadGuys = target.getActiveRowers()
							target.kill(deadGuys.pick_random())
				
				print("Ballista After: ", target.name, ", E: ", target.getEngineers().size(), " , DC: ",
				target.getDeckCrew().size(), ", M: ",
				target.getArchers().size() + target.getJavelineers().size() + target.getSoldiers().size(),
				", RR: ", target.getReserveRowers().size(), ", AR: ", target.getActiveRowers().size())
				print("--------------------------------")
