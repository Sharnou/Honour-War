	if int(hero["materials"].get("Phracon",0))<2 or int(hero["zeny"])<80:
		log_message("Crafting requires 2 Phracon and 80 Zeny.")
		return
	hero["materials"]["Phracon"]-=2
	hero["zeny"]-=80
	var item:String=CLASSES[hero["class"]]["weapon"]+" Core"
	hero["inventory"][item]=int(hero["inventory"].get(item,0))+1
	log_message("Crafted %s." % item)
	save_game()
	update_ui()

func buy_material()->void: