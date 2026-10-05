extends Node


func archer_fire(ship):
	if ship.enemy_target and ship.marines.filter(func(guy): return guy is Archer) != null:
		var target = ship.enemy_target
		var my_archers = ship.marines.filter(func(guy): return guy is Archer)
		for i in my_archers.size():
			#Ask about "for each each 6 go to CCC for LRF"
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
	#			print("After: ", target.name, " has fighters: ", target.fighters.size())

func ballista_fire(ship):
	if ship.ballista and ship.enemy_target and ship.boarding_action > 0:
		var target = ship.enemy_target
		#Ballista can only roll 1-4 (i.e. hit only engineers, deck crew, and marines. So check if they are available tot hit)
		var eng = target.engineers
		var deck = target.deck_crew
		var mar = target.marines.filter(func(guy): return guy is Marine)
		if eng or deck or mar:
			var temp = true
			while temp:
				var roll = randi_range(1, 4)
				#Make it so that range thing ^
				if roll == 6:
					roll = randi_range(2, 12)
					while roll == 12:
						roll = randi_range(2, 12)
					match roll:
						2:
							#Engineer Killed
							var crew = target.engineers
							if crew:
								for mate in crew:
									target.fighters.erase(mate)
									crew.erase(mate)
									temp = false
									break
						3,9,10,11:
							#Deck Crew Killed
							var crew = target.deck_crew
							if crew:
								for mate in crew:
									target.fighters.erase(mate)
									crew.erase(mate)
									temp = false
									break
									
						4,5:
							#Random Marine Killed
							var crew = ship.enemy_target.marines.filter(func(guy): return guy is Marine)
							if crew:
								for mate in crew:
									target.fighters.erase(mate)
									crew.erase(mate)
									temp = false
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
	#			print("After: ", target.name, " has fighters: ", target.fighters.size())
	#				print("IN")
	#			print("Done Ballista-ing")
