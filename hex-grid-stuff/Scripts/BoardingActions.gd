extends Node


func determine_fighting(ship):
	var target = ship.boarding_target
	ship.boarding_prepped = true
	target.boarding_prepped = true
	#Get Correct Fighting Order from Fighters
	var class_priority = [Soldier, Javelineer, Archer, Engineer, DeckCrew]
	#My Fighters
	var my_new_fighters = ship.fighters
	my_new_fighters.sort_custom(func(a, b):
		var index_a = class_priority.find(a.get_script())
		var index_b = class_priority.find(b.get_script())
		return index_a < index_b
	)
	#Enemy Fighters
	var enemy_new_fighters = target.fighters
	enemy_new_fighters.sort_custom(func(a, b):
		var index_a = class_priority.find(a.get_script())
		var index_b = class_priority.find(b.get_script())
		return index_a < index_b
	)
	
	ship.boarding_archers = []
	ship.boarding_javelins = []
	ship.boarding_melee = []
	target.boarding_archers = []
	target.boarding_javelins = []
	target.boarding_melee = []
	
	#Get my soldiers and enemy soldiers then see if I need to add Auxiliary
	#Then check if enemy needs to add Auxiliary
	#Check if first boarding action
		#If yes then do Archery
	#Check Javelins
	
	#Get my soldiers and enemy soldiers
	var items = my_new_fighters.filter(func(guy): return guy is Soldier)
	for item in items:
		ship.boarding_melee.append(item)
		my_new_fighters.erase(item)
	items = enemy_new_fighters.filter(func(guy): return guy is Soldier)
	for item in items:
		target.boarding_melee.append(item)
		my_new_fighters.erase(item)
	
	#See if I need to add Auxiliary to either side
	if ship.boarding_melee.size() < target.boarding_melee.size():
		for item in my_new_fighters:
			ship.boarding_melee.append(item)
			my_new_fighters.erase(item)
			if ship.boarding_melee.size() == target.boarding_melee.size(): break
	if target.boarding_melee.size() < ship.boarding_melee.size():
		for item in enemy_new_fighters:
			target.boarding_melee.append(item)
			enemy_new_fighters.erase(item)
			if target.boarding_melee.size() == ship.boarding_melee.size(): break
	
	#Get my archers and javelins
	ship.boarding_archers = my_new_fighters.filter(func(guy): return guy is Archer)
	ship.boarding_javelins = my_new_fighters.filter(func(guy): return guy is Javelineer)
	
	#Get enemy archers and javelins
	target.boarding_archers = enemy_new_fighters.filter(func(guy): return guy is Archer)
	target.boarding_javelins = enemy_new_fighters.filter(func(guy): return guy is Javelineer)
	print("Boarding Determination Done")

func boarding_archer_fire(ship):
	if ship.enemy_target and ship.boarding_archers != null:
		var target = ship.enemy_target
		var my_archers = ship.boarding_archers
		for i in my_archers.size():
			var roll = randi_range(1, 6)
			if roll == 6:
				roll = randi_range(2, 12)
	#			print("Before: ", target.name, " has fighters: ", target.fighters.size())
	#			print(roll)
				match roll:
					2:
						#Engineer Killed
						var crew = target.engineers
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
					3,9,10,11:
						#Deck Crew Killed
						var crew = target.deck_crew
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
								
					4,5:
						#Random Marine Killed
						var crew = ship.enemy_target.marines.filter(func(guy): return guy is Marine)
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
					6,7,8:
						#Rower Killed
						#change it to do reserve rowers first
						var crew = target.rowers
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
					
				ship.boarding_action += 1
	#			print("After: ", target.name, " has fighters: ", target.fighters.size())

func boarding_javelin_fire(ship):
	if ship.enemy_target and ship.boarding_javelins != null:
		var target = ship.enemy_target
		var my_javelins = ship.boarding_javelins
		for i in my_javelins.size():
			var roll = randi_range(1, 6)
			if roll >= 5:
				roll = randi_range(2, 12)
	#			print("Before: ", target.name, " has fighters: ", target.fighters.size())
	#			print(roll)
				match roll:
					2:
						#Engineer Killed
						var crew = target.engineers
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
					3:
						#2 Deck Crew Killed
						var crew = target.deck_crew
						if crew:
							var index = 0
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								index += 1
								if index == 2: break
								
					4,5:
						#Random Marine Killed
						var crew = ship.enemy_target.marines.filter(func(guy): return guy is Marine)
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
					6,8:
						#2 Rower Killed
						#change it to do reserve rowers first
						var crew = target.rowers
						if crew:
							var index = 0
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								index += 1
								if index == 2: break
					7:
						#Rower Killed
						#change it to do reserve rowers first
						var crew = target.rowers
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
					9,10,11:
						#Deck Crew Killed
						#change it to do reserve rowers first
						var crew = target.deck_crew
						if crew:
							for mate in crew:
								target.fighters.erase(mate)
								crew.erase(mate)
								break
				ship.boarding_action += 1
	#			print("After: ", target.name, " has fighters: ", target.fighters.size())
