extends Node


func determineFighting(ship: Ship):
	var target = ship._enemyTarget
	#Can't boarding action same team
	if ship._owner == target._owner:
		print("Boarding Target is same team!")
		return
	
	ship._boardingPrepped = true
	target._boardingPrepped = true
	#Get Correct Fighting Order from Fighters
	var class_priority = [Character.Marine.Soldier, Character.Marine.Javelineer, Character.Marine.Archer, Character.Engineer, Character.DeckCrew]
	
	#Sort fighters so that grabbing them for melee based on type is easier
	#My Fighters
	var my_new_fighters = []
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Marine.Soldier))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Marine.Archer))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.Engineer))
	my_new_fighters.append_array(ship._fighters.filter(func(guy): return guy is Character.DeckCrew))
	#Enemy Fighters
	var enemy_new_fighters = []
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Marine.Soldier))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Marine.Archer))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.Engineer))
	enemy_new_fighters.append_array(target._fighters.filter(func(guy): return guy is Character.DeckCrew))
	
	ship._boardingArchers.clear()
	ship._boardingJavelins.clear()
	ship._boardingMelee.clear()
	target._boardingArchers.clear()
	target._boardingJavelins.clear()
	target._boardingMelee.clear()
	
	#Get my soldiers and enemy soldiers
	var items = my_new_fighters.filter(func(guy): return guy is Character.Marine.Soldier)
	for item in items:
		ship._boardingMelee.append(item)
		my_new_fighters.erase(item)
	items = enemy_new_fighters.filter(func(guy): return guy is Character.Marine.Soldier)
	for item in items:
		target._boardingMelee.append(item)
		my_new_fighters.erase(item)
	
	#See if I need to add Auxiliary to either side
	if ship._boardingMelee.size() < target._boardingMelee.size():
		for item in my_new_fighters:
			ship._boardingMelee.append(item)
			my_new_fighters.erase(item)
			if ship._boardingMelee.size() == target._boardingMelee.size(): break
	if target._boardingMelee.size() < ship._boardingMelee.size():
		for item in enemy_new_fighters:
			target._boardingMelee.append(item)
			enemy_new_fighters.erase(item)
			if target._boardingMelee.size() == ship._boardingMelee.size(): break
	
	#Keep adding to Melee until either X_new_fighters == 0
	while true:
		ship._boardingMelee.append(my_new_fighters[0])
		my_new_fighters.erase(my_new_fighters[0])
		target._boardingMelee.append(enemy_new_fighters[0])
		enemy_new_fighters.erase(enemy_new_fighters[0])
		if my_new_fighters.size() == 0 or enemy_new_fighters.size() == 0: break
		
	#Get Archers that are left
	if ship._boardingCounter == 0:
		ship._boardingArchers.append_array(my_new_fighters.filter(func(guy): return guy is Character.Marine.Archer))
	if target._boardingCounter == 0:
		target._boardingArchers.append_array(enemy_new_fighters.filter(func(guy): return guy is Character.Marine.Archer))
		
	#Get Javelins that are left
	ship._boardingJavelins.append_array(my_new_fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	target._boardingJavelins.append_array(enemy_new_fighters.filter(func(guy): return guy is Character.Marine.Javelineer))
	print("Boarding Determination Done")


func boardingArcherFire(ship):
	if ship._enemyTarget and ship._boardingArchers.size() > 0:
		print("Attempting BAF")
		var target = ship._enemyTarget
		var my_archers = ship._boardingArchers
		for i in my_archers.size():
			var roll = randi_range(1, 6)
			if roll == 6:
				roll = randi_range(2, 12)
				print("\nBefore: ", target.name, " has fighters: ", target._fighters.size())
	#			print(roll)
				match randi_range(2, 12):
					#Engineer Killed
					2:
						if target.getEngineers():
							killAndFighter(target, target.getEngineers())
					
					#Deck Crew Killed
					3,9,10,11:
						if target.getDeckCrew():
							killAndFighter(target, target.getDeckCrew())
					
					#Random Marine Killed
					4,5:
						match randi_range(1, 3):
							1:
								if target.getArchers():
									killAndFighter(target, target.getArchers())
							2:
								if target.getJavelineers():
									killAndFighter(target, target.getJavelineers())
							3:
								if target.getSoldiers():
									killAndFighter(target, target.getSoldiers())
					
					#Rower Killed
					6,7,8:
						if target.getReserveRowers():
							killAndFighter(target, target.getReserveRowers())
						elif target.getActiveRowers():
							killAndFighter(target, target.getActiveRowers())
				print("After: ", target.name, " has fighters: ", target._fighters.size())
					
		ship._boardingCounter += 1

func boardingJavelineFire(ship):
	if ship._enemyTarget and ship._boardingJavelins.size() > 0:
		print("Attempting BJF")
		var target = ship._enemyTarget
		var my_javelins = ship._boardingJavelins
		for i in my_javelins.size():
			var roll = randi_range(1, 6)
			if roll >= 5:
				roll = randi_range(2, 12)
				print("\nBefore: ", target.name, " has fighters: ", target._fighters.size())
	#			print(roll)
				match randi_range(2, 12):
					#Engineer Killed
					2:
						if target.getEngineers():
							killAndFighter(target, target.getEngineers())
					
					#Deck Crew Killed
					3,9,10,11:
						if target.getDeckCrew():
							killAndFighter(target, target.getDeckCrew())
					
					#Random Marine Killed
					4,5:
						match randi_range(1, 3):
							1:
								if target.getArchers():
									killAndFighter(target, target.getArchers())
							2:
								if target.getJavelineers():
									killAndFighter(target, target.getJavelineers())
							3:
								if target.getSoldiers():
									killAndFighter(target, target.getSoldiers())
					
					#Rower Killed
					6,7,8:
						if target.getReserveRowers():
							killAndFighter(target, target.getReserveRowers())
						elif target.getActiveRowers():
							killAndFighter(target, target.getActiveRowers())
				print("After: ", target.name, " has fighters: ", target._fighters.size())
					
		ship._boardingCounter += 1

func killAndFighter(target, deadGuys):
	var guy = deadGuys.pick_random()
	target.kill(guy)
	target._fighters.erase(guy)
