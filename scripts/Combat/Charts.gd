extends Node

const _Log = preload("res://scripts/turn/game_log.gd")

func singleCrewCasualty(target: Ship):
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

func multiCrewCasualty(target: Ship):
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

func catapultHit(target: Ship):
	match randi_range(2, 12):
		#Beak Damage
		2:
			if target._beakHP > 0: target._beakHP -= 1
		
		#If mast up it falls down, Roll Crew Casualty Chart (CCC)
		3:
			if target._isMastUp:
				target.set_mast_down(true)
				multiCrewCasualty(target)
		
		#Mast takes 1 damage, if 0 then roll CCC
		4:
			if target._isMastUp:
				target._mastHP -= 1
				if target._mastHP == 0:
					target.set_mast_down(true)
					multiCrewCasualty(target)
		
		#If a ship has a Catapult or Ballitsa it is destroyed, otherwise roll CCC
		5:
			## Hulls only carry one siege weapon now, so check both helpers.
			if target.hasBallista() or target.hasCatapult():
				var temp = true
				while temp:
					match randi_range(1, 2):
						1:
							if target.hasBallista():
								for j in target._ballista._engineers.size():
									target._ballista._engineers[j]._target = null
								target._catapult = null
								temp = false
							else:
								for j in target._catapult._engineers.size():
									target._catapult._engineers[j]._target = null
								target._catapult = null
								temp = false
							
			else: multiCrewCasualty(target)
		
		#One flotation damage
		6,9:
			flotationDamage(target, 1)
		
		#Roll CCC
		7,8:
			multiCrewCasualty(target)
		
		#One oar bank = rowers are killed
		10,11:
			var banks = target.getBanks()
			banks[0].removeBank(target)
		
		#1 flotation damage and 1 hole. Immediately check to Repair Hole
		12:
			flotationDamage(target, 1)
			target._holes += 1
			repairHole(target)

func collisionCriticalHit(target: Ship, isRamming: bool, damageModifier: int):
	match randi_range(2, 12):
		#Destroy Beak if Ramming, else Suffer 2 flotation damage
		2:
			if isRamming: target._beakHP = 0
			else: flotationDamage(target, 2 * damageModifier)
		
		#If ship has a catapult destroy it, else suffer 2 flotation damage
		3:
			if target.hasBallista():
				for j in target._ballista._engineers.size():
					target._ballista._engineers[j]._target = null
				target._ballista = null
			else: flotationDamage(target, 2 * damageModifier)
		
		#If ship has a ballista destroy it, else suffer 2 flotation damage
		4:
			if target.hasCatapult():
				for j in target._catapult._engineers.size():
					target._catapult._engineers[j]._target = null
				target._catapult = null
			else: flotationDamage(target, 2 * damageModifier)
		
		#Suffer 1 additional flotation damage
		5:
			flotationDamage(target, 1 * damageModifier)
		
		#Roll Crew Causalties Chart
		6:
			singleCrewCasualty(target)
		
		#One oar bank + rowers are destroyed
		8,9:
			var banks = target.getBanks()
			banks[0].removeBank(target)
		
		#1-3 oar banks + rowers are killed
		10:
			var banks = target.getBanks()
			for i in randi_range(1, 3):
				banks[i].removeBank(target)
		
		#If Mast up destory, otherwise lose 1 deck crew
		11:
			if target._isMastUp:
				target._mastHP = 0
				target.set_mast_down(true)
			elif target.getDeckCrew():
				Global.addToDead(target, target.getDeckCrew())
		
		#If mast up destroy and 1 float damage, else lose 3 rowers
		12:
			if target._isMastUp:
				target._mastHP = 0
				target.set_mast_down(true)
				flotationDamage(target, 1)
			elif target.getReserveRowers():
				Global.addToDead(target, target.getReserveRowers())
			elif target.getActiveRowers():
				Global.addToDead(target, target.getActiveRowers())

func flotationDamage(ship: Ship, amount):
	while ship._flotationHits > 0:
		for i in int(ceil(amount)):		#Excutive decision to round up
			ship._flotationHits -= 1
		break

func repairHole(target: Ship):
	var roll = randi_range(1, 6)
	
	#If < Num of Eng the hole is fixed and 1/2 flotation damage is repaired per Engineer (round down)
	target._holes -= 1
	if roll < target._engineers.size():
		for i in target._engineers.size():
			target._flotationHits += .5
	
	#If = the hole is fixed
	elif roll < target._engineers.size():
		target._holes -= 1
	
	#If > hole is fixed but ship still suffers 1 flotation damage
	elif roll < target._engineers.size():
		target._holes -= 1
		flotationDamage(target, 1)
	
	#Play Sound
	AudioController.play_sfx("boat_repair", -15)

func rammingResults(rammer: Ship, avoider: Ship):
	if rammer._speed <= randi_range(2, 12):
		var bothSpeed = 0
		var avSpeed = avoider._speed
		var damageModifier = 1
		if avSpeed < 0:
			avSpeed = 1
			rammer._ramAction = 1
		
		if rammer._beakHP < rammer._beakHPMax:
			damageModifier = .5
		
		#Beak to Beak
		if ceil(fposmod(rammer.rotation_degrees.y + 180, 360)) == ceil(avoider.rotation_degrees.y):
			#Both Beak to Beak
			if rammer._ramAction == 1 and avoider._ramAction == 1:
				bothSpeed = rammer._speed + avSpeed
			
			#One is attempting Beak to Beak
			if rammer._ramAction != 0 and avoider._ramAction != 0 and rammer._ramAction != avoider._ramAction:
				if avoider._speed != 0:
					bothSpeed = rammer._speed + (avSpeed / 2)
				else:
					bothSpeed = rammer._speed
		
		#Both are attempting to Ram opponents Front 1/4th
		#If rammer ramming avoider in front 1/4th
		if ceil(fposmod(rammer.rotation_degrees.y + 180, 360)) == ceil(fposmod(avoider.rotation_degrees.y + 60 ,360)) or ceil(fposmod(rammer.rotation_degrees.y + 180, 360)) == ceil(fposmod(avoider.rotation_degrees.y - 60 ,360)):
			var temp = BoardingActions.returnSmallest(rammer._speed, avSpeed)
			if temp != 0:
				bothSpeed = BoardingActions.returnLarget(rammer._speed, avSpeed) + (BoardingActions.returnSmallest(rammer._speed, avSpeed) / 2)
			else:
				bothSpeed = BoardingActions.returnLarget(rammer._speed, avSpeed)
			damageModifier = 2
		
		#Attenpting to Ram opponents Rear 1/4th
		#If rammer ramming avoider in rear 1/4th
		if ceil(fposmod(rammer.rotation_degrees.y + 180, 360)) == ceil(fposmod(avoider.rotation_degrees.y + 120 ,360)) or ceil(fposmod(rammer.rotation_degrees.y + 180, 360)) == ceil(fposmod(avoider.rotation_degrees.y - 120 ,360)):
			if avoider._speed != 0:
				bothSpeed = rammer._speed + (avSpeed / 2)
			else:
				bothSpeed = rammer._speed
		
		#Attenpting to Ram opponents Stern
		if ceil(rammer.rotation_degrees.y) == ceil(fposmod(avoider.rotation_degrees.y + 180 ,360)):
			if avoider._speed != 0:
				bothSpeed = rammer._speed + (avSpeed / 4)
			else:
				bothSpeed = rammer._speed
		
		#Ram Effects
		var roll = randi_range(1, 6)
		
		#If a ship has it's mast UP at the time of the ram or collision it auto suffers another roll
		if rammer._isMastUp:
			collisionCriticalHit(rammer, true, damageModifier)
		if avoider._isMastUp:
			collisionCriticalHit(avoider, true, damageModifier)
		
		#Successful Ram
		if roll < bothSpeed:
			#Rammed ship gains a hole
			avoider._holes += 1		#Might need to change to both ships depending on roll
			
			#Flotation Damage
			flotationDamage(avoider, rammer._speed)
			
			#Roll
			if roll >= 5:
				collisionCriticalHit(avoider, true, damageModifier)
			elif roll == 1:
				collisionCriticalHit(rammer, true, damageModifier)
			
			#Set both ship speeds to 0
			rammer._speed = 0
			avoider._speed = 0
		
		#Partial Ram
		if roll == bothSpeed:
			#Flotation Damage
			flotationDamage(avoider, (rammer._speed / 2) * damageModifier )
			
			#Roll
			if roll == 6:
				collisionCriticalHit(avoider, true, damageModifier)
			elif roll == 1:
				collisionCriticalHit(rammer, true, damageModifier)
			
			#Set both ship speeds to 1/2 speed
			rammer._speed = ceil(rammer._speed / 2)
			if avoider._speed > 0:
				avoider._speed = ceil(avoider._speed / 2)
			else: avoider._speed = 0
		
		#Collision
		if roll > bothSpeed:
			collision(roll, rammer, avoider, damageModifier)
	
	
	print("Get Rammed!")


func rammingIsland(rammer: Ship, phase: int):
	#Set Damage Modifier
	var damageModifier = 1
	
	#Rammed ship gains a hole
	rammer._holes += 1		#Might need to change to both ships depending on roll
	
	#Flotation Damage
	var amount = ceil(rammer._speed * 0.25)
	flotationDamage(rammer, amount)
	
	#Set ship speed to 0
	rammer._speed = 0
	
	#Roll
	if randi_range(1, 6) == 1:
		collisionCriticalHit(rammer, true, damageModifier)
	
	rammer._stranded = true
	rammer._stranded_phase = phase
	rammer._inCollision = true
	
	#Play Beaching Sound
	AudioController.play_sfx("beached_boat", -10)
	
	#Kill ship if it hits a rock
	if rammer._tile.biome == "Rock" or rammer._tile.biome == "Big Rock":
		rammer._flotationHits = 0
		_Log.push("%s hit a rock and sank" % [rammer.name])



func collision(roll: int, rammer: Ship, avoider: Ship, damageModifier: int):
	#Roll
	if roll == 6:
		collisionCriticalHit(avoider, true, damageModifier)
	elif roll == 1:
		collisionCriticalHit(rammer, true, damageModifier)
	
	#Set both ship speeds to 1/4 speed
	rammer._speed = ceil(rammer._speed / 4)
	if avoider._speed > 0:
		avoider._speed = ceil(avoider._speed / 4)
	else: avoider._speed = 0
	
	#If enemies set both to boariding
	if rammer._owner != avoider._owner:
		rammer._inBoarding = true
		avoider._inBoarding = true


func shear(ship, target: Ship, firstShip: Ship, secondShip: Ship):
	print("Shear")
	#Get a roll for first ship
	var roll = randi_range(2, 12)
	#If roll above shearers speed then fail
	if roll > ship._speed:
		#Prompt secondShip for decision
		#TEMP rng for 2nd Ship
		var roll2 = randi_range(1, 2)
		match roll2:
			#Ram
			1:
				Charts.rammingResults(secondShip, firstShip)
			#Collision
			2:
				Charts.collision(roll2, secondShip, firstShip, 1)
	
	elif roll == ship._speed:
		#Half reaming oar banks + rowers equal to those banks are lost
		var banks = target.getBanks()
		for i in int(ceil(banks.size() / 2)):
			banks[i].removeBank(target)
		
	elif roll < ship._speed:
		#Collision
		Charts.collision(roll, firstShip, secondShip, 1)
	
		#Both ships are now in a BA
		ship._inBoarding = true
		target._inBoarding = true
