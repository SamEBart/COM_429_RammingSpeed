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
	print("Attempting BAF")
	var target = ship._enemyTarget
	ship._boardingPrepped = true
	for i in ship._baordingArchers.size():
		if randi_range(1, 6) == 6:
			Charts.singleCrewCasualty(target)
		ship._boardingCounter += 1

func boardingJavelineFire(ship):
	print("Attempting BJF")
	var target = ship._enemyTarget
	ship._boardingPrepped = true
	for i in ship._boardingJavelins.size():
		if randi_range(1, 6) >= 5:
			Charts.singleCrewCasualty(target)
		ship._boardingCounter += 1

func preBoardingMelee(ship):
	var target = ship._enemyTarget
	var myRoll
	var targetRoll
	if target:
		var total = returnLarget(ship._boardingMelee.size(), target._boardingMelee.size())
		for num in total:
			#If Ship Melee is Soldier
			if ship._boardingMelee[num] is Character.Marine.Soldier:
				myRoll = randi_range(1, 6)
				#If Soldier v Soldier
				if target._boardingMelee[num] is Character.Marine.Soldier:
					targetRoll = randi_range(1, 6)
					#Ship Hits
					if myRoll == 6:
						#If both hit then skip
						if targetRoll == 6:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll == 6:
						boardingMelee(ship)
					
				#Else Soldier v Aux
				else:
					targetRoll = randi_range(1, 8)
					#Ship Hits
					if myRoll >= 5:
						#If both hit then skip
						if targetRoll == 8:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll == 8:
						boardingMelee(ship)
			
			#Else Ship Melee is Aux
			else:
				myRoll = randi_range(1, 8)
				#If Aux v Soldier
				if target._boardingMelee[num] is Character.Marine.Soldier:
					targetRoll = randi_range(1, 6)
					#Ship Hits
					if myRoll == 8:
						#If both hit then skip
						if targetRoll >= 5:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll >= 5:
						boardingMelee(ship)
				
				#Else Aux v Aux
				else:
					targetRoll = randi_range(1, 8)
					#Ship Hits
					if myRoll >= 7:
						#If both hit then skip
						if targetRoll >= 7:
							continue
						#Ship hits only
						boardingMelee(ship)
					
					#Target Hits Only
					elif targetRoll >= 7:
						boardingMelee(ship)

func boardingMelee(ship):
	var target = ship._enemyTarget
	Charts.multiCrewCasualty(target)

func returnLarget(a, b):
	return a if a > b else b
