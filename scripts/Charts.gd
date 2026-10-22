extends Node

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
				target._isMastUp = false
				target._isMastDown = true
				multiCrewCasualty(target)
		
		#Mast takes 1 damage, if 0 then roll CCC
		4:
			if target._isMastUp:
				target._mastHP -= 1
				if target._mastHP == 0:
					target._isMastUp = false
					target._isMastDown = true
					multiCrewCasualty(target)
		
		#If a ship has a Catapult or Ballitsa it is destroyed, otherwise roll CCC
		5:
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

func collisionCriticalHit(target: Ship, isRamming: bool):
	match randi_range(2, 12):
		#Destroy Beak if Ramming, else Suffer 2 flotation damage
		2:
			if isRamming: target._beakHP = 0
			else: flotationDamage(target, 2)
		
		#If ship has a catapult destroy it, else suffer 2 flotation damage
		3:
			if target.hasCatapult():
				for j in target._ballista._engineers.size():
					target._ballista._engineers[j]._target = null
				target._ballista = null
			else: flotationDamage(target, 2)
		
		#If ship has a ballista destroy it, else suffer 2 flotation damage
		4:
			if target.hasBallista():
				for j in target._catapult._engineers.size():
					target._catapult._engineers[j]._target = null
				target._catapult = null
			else: flotationDamage(target, 2)
		
		#Suffer 1 additional flotation damage
		5:
			flotationDamage(target, 1)
		
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
				target._isMastDown = true
			elif target.getDeckCrew():
				Global.addToDead(target, target.getDeckCrew())
		
		#If mast up destroy and 1 float damage, else lose 3 rowers
		12:
			if target._isMastUp:
				target._mastHP = 0
				target._isMastDown = true
				flotationDamage(target, 1)
			elif target.getReserveRowers():
				Global.addToDead(target, target.getReserveRowers())
			elif target.getActiveRowers():
				Global.addToDead(target, target.getActiveRowers())

func flotationDamage(ship: Ship, amount: int):
	while ship._flotationHits > 0:
		for i in amount:
			ship._flotationHits -= 1

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

func ramming(rammer: Ship, avoider: Ship):
	var bothSpeed
	
	#Beak to Beak
	if fposmod(rammer.rotation_degrees.y + 180, 360) == avoider.rotation_degrees.y or fposmod(rammer.rotation_degrees.y - 180, 360) == avoider.rotation_degrees.y:
		#Both Beak to Beak
		if rammer._ramAction == 1 and avoider._ramAction == 1:
			bothSpeed = rammer._speed + avoider._speed
		
		#One Beak to Beak
		if rammer._ramAction != 0 and avoider._ramAction != 0 and rammer._ramAction != avoider._ramAction:
			if avoider._speed != 0:
				bothSpeed = rammer._speed + (avoider._speed / 2)
			else:
				bothSpeed = rammer._speed
	
	#One is attempting Bow to Bow
