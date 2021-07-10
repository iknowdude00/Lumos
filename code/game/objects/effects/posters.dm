// This is synced up to the poster placing animation.
#define PLACE_SPEED 37

// The poster item
// SKYRAT EDIT: Moving icon to be modular
/obj/item/poster
	name = "poorly coded poster"
	desc = "You probably shouldn't be holding this."
	icon = 'icons/obj/posters.dmi'
	force = 0
	resistance_flags = FLAMMABLE
	var/poster_type
	var/obj/structure/sign/poster/poster_structure

/obj/item/poster/Initialize(mapload, obj/structure/sign/poster/new_poster_structure)
	. = ..()
	poster_structure = new_poster_structure
	if(!new_poster_structure && poster_type)
		poster_structure = new poster_type(src)

	// posters store what name and description they would like their
	// rolled up form to take.
	if(poster_structure)
		name = poster_structure.poster_item_name
		desc = poster_structure.poster_item_desc
		icon_state = poster_structure.poster_item_icon_state

		name = "[name] - [poster_structure.original_name]"

/obj/item/poster/Destroy()
	poster_structure = null
	. = ..()

// These icon_states may be overridden, but are for mapper's convinence
/obj/item/poster/random_contraband
	name = "random contraband poster"
	poster_type = /obj/structure/sign/poster/contraband/random
	icon_state = "rolled_poster"

/obj/item/poster/random_official
	name = "random official poster"
	poster_type = /obj/structure/sign/poster/official/random
	icon_state = "rolled_legit"

// The poster sign/structure

/obj/structure/sign/poster
	name = "poster"
	var/original_name
	desc = "A large piece of space-resistant printed paper."
	icon = 'icons/obj/posters.dmi'
	plane = ABOVE_WALL_PLANE
	anchored = TRUE
	buildable_sign = FALSE //Cannot be unwrenched from a wall.
	var/ruined = FALSE
	var/random_basetype
	var/never_random = FALSE // used for the 'random' subclasses.

	var/poster_item_name = "hypothetical poster"
	var/poster_item_desc = "This hypothetical poster item should not exist, let's be honest here."
	var/poster_item_icon_state = "rolled_poster"
	var/poster_item_type = /obj/item/poster

/obj/structure/sign/poster/Initialize()
	. = ..()
	if(random_basetype)
		randomise(random_basetype)
	if(!ruined)
		original_name = name // can't use initial because of random posters
		name = "poster - [name]"
		desc = "A large piece of space-resistant printed paper. [desc]"

	addtimer(CALLBACK(src, /datum.proc/_AddElement, list(/datum/element/beauty, 300)), 0)

/obj/structure/sign/poster/proc/randomise(base_type)
	var/list/poster_types = subtypesof(base_type)
	var/list/approved_types = list()
	for(var/t in poster_types)
		var/obj/structure/sign/poster/T = t
		if(initial(T.icon_state) && !initial(T.never_random))
			approved_types |= T

	var/obj/structure/sign/poster/selected = pick(approved_types)

	name = initial(selected.name)
	desc = initial(selected.desc)
	icon_state = initial(selected.icon_state)
	poster_item_name = initial(selected.poster_item_name)
	poster_item_desc = initial(selected.poster_item_desc)
	poster_item_icon_state = initial(selected.poster_item_icon_state)
	ruined = initial(selected.ruined)


/obj/structure/sign/poster/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/wirecutters))
		I.play_tool_sound(src, 100)
		if(ruined)
			to_chat(user, "<span class='notice'>You remove the remnants of the poster.</span>")
			qdel(src)
		else
			to_chat(user, "<span class='notice'>You carefully remove the poster from the wall.</span>")
			roll_and_drop(user.loc)

/obj/structure/sign/poster/attack_hand(mob/user)
	. = ..()
	if(.)
		return
	if(ruined)
		return
	visible_message("[user] rips [src] in a single, decisive motion!" )
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 100, 1)

	var/obj/structure/sign/poster/ripped/R = new(loc)
	R.pixel_y = pixel_y
	R.pixel_x = pixel_x
	R.add_fingerprint(user)
	qdel(src)

/obj/structure/sign/poster/proc/roll_and_drop(loc)
	pixel_x = 0
	pixel_y = 0
	var/obj/item/poster/P = new poster_item_type(loc, src)
	forceMove(P)
	return P

//separated to reduce code duplication. Moved here for ease of reference and to unclutter r_wall/attackby()
/turf/closed/wall/proc/place_poster(obj/item/poster/P, mob/user)
	if(!P.poster_structure)
		to_chat(user, "<span class='warning'>[P] has no poster... inside it? Inform a coder!</span>")
		return

	// Deny placing posters on currently-diagonal walls, although the wall may change in the future.
	if (smooth & SMOOTH_DIAGONAL)
		for (var/O in overlays)
			var/image/I = O
			if(copytext(I.icon_state, 1, 3) == "d-") //3 == length("d-") + 1
				return

	var/stuff_on_wall = 0
	for(var/obj/O in contents) //Let's see if it already has a poster on it or too much stuff
		if(istype(O, /obj/structure/sign/poster))
			to_chat(user, "<span class='warning'>The wall is far too cluttered to place a poster!</span>")
			return
		stuff_on_wall++
		if(stuff_on_wall == 3)
			to_chat(user, "<span class='warning'>The wall is far too cluttered to place a poster!</span>")
			return

	to_chat(user, "<span class='notice'>You start placing the poster on the wall...</span>"	)

	var/obj/structure/sign/poster/D = P.poster_structure

	var/temp_loc = get_turf(user)
	flick("poster_being_set",D)
	D.forceMove(src)
	qdel(P)	//delete it now to cut down on sanity checks afterwards. Agouri's code supports rerolling it anyway
	playsound(D.loc, 'sound/items/poster_being_created.ogg', 100, 1)

	if(do_after(user, PLACE_SPEED, target=src))
		if(!D || QDELETED(D))
			return

		if(iswallturf(src) && user && user.loc == temp_loc)	//Let's check if everything is still there
			to_chat(user, "<span class='notice'>You place the poster!</span>")
			return

	to_chat(user, "<span class='notice'>The poster falls down!</span>")
	D.roll_and_drop(temp_loc)

// Various possible posters follow

/obj/structure/sign/poster/ripped
	ruined = TRUE
	icon_state = "poster_ripped"
	name = "ripped poster"
	desc = "You can't make out anything from the poster's original print. It's ruined."

/obj/structure/sign/poster/random
	name = "random poster" // could even be ripped
	icon_state = "random_anything"
	never_random = TRUE
	random_basetype = /obj/structure/sign/poster

/obj/structure/sign/poster/contraband
	poster_item_name = "contraband poster"
	poster_item_desc = "This poster comes with its own automatic adhesive mechanism, for easy pinning to any vertical surface. Its vulgar themes have marked it as contraband aboard Nanotrasen space facilities."
	poster_item_icon_state = "rolled_poster"

/obj/structure/sign/poster/contraband/random
	name = "random contraband poster"
	icon_state = "random_contraband"
	never_random = TRUE
	random_basetype = /obj/structure/sign/poster/contraband

/obj/structure/sign/poster/contraband/free_tonto
	name = "Free Tonto"
	desc = "A salvaged shred of a much larger flag, colors bled together and faded from age."
	icon_state = "poster1"

/obj/structure/sign/poster/contraband/atmosia_independence
	name = "Atmosia Declaration of Independence"
	desc = "A relic of a failed rebellion."
	icon_state = "poster2"

/obj/structure/sign/poster/contraband/fun_police
	name = "Fun Police"
	desc = "A poster condemning the station's security forces."
	icon_state = "poster3"

/obj/structure/sign/poster/contraband/lusty_xenomorph
	name = "Lusty Xenomorph"
	desc = "A heretical poster depicting the titular star of an equally heretical book."
	icon_state = "poster4"

/obj/structure/sign/poster/contraband/post_ratvar
	name = "Post This Ratvar"
	desc = "Oh what in the hell? Those cultists have animated paper technology and they use it for a meme?"
	icon_state = "postvar"

/obj/structure/sign/poster/contraband/syndicate_recruitment
	name = "Syndicate Recruitment"
	desc = "See the galaxy! Shatter corrupt megacorporations! Join today!"
	icon_state = "poster5"

/obj/structure/sign/poster/contraband/clown
	name = "Clown"
	desc = "Honk."
	icon_state = "poster6"

/obj/structure/sign/poster/contraband/smoke
	name = "Smoke"
	desc = "A poster advertising a rival corporate brand of cigarettes."
	icon_state = "poster7"

/obj/structure/sign/poster/contraband/grey_tide
	name = "Grey Tide"
	desc = "A rebellious poster symbolizing assistant solidarity."
	icon_state = "poster8"

/obj/structure/sign/poster/contraband/missing_gloves
	name = "Missing Gloves"
	desc = "This poster references the uproar that followed Nanotrasen's financial cuts toward insulated-glove purchases."
	icon_state = "poster9"

/obj/structure/sign/poster/contraband/hacking_guide
	name = "Hacking Guide"
	desc = "This poster details the internal workings of the common Nanotrasen airlock. Sadly, it appears out of date."
	icon_state = "poster10"

/obj/structure/sign/poster/contraband/rip_badger
	name = "RIP Badger"
	desc = "This seditious poster references Nanotrasen's genocide of a space station full of badgers."
	icon_state = "poster11"

/obj/structure/sign/poster/contraband/ambrosia_vulgaris
	name = "Ambrosia Vulgaris"
	desc = "This poster is lookin' pretty trippy man."
	icon_state = "poster12"

/obj/structure/sign/poster/contraband/donut_corp
	name = "Donut Corp."
	desc = "This poster is an unauthorized advertisement for Donut Corp."
	icon_state = "poster13"

/obj/structure/sign/poster/contraband/eat
	name = "EAT."
	desc = "This poster promotes rank gluttony."
	icon_state = "poster14"

/obj/structure/sign/poster/contraband/tools
	name = "Tools"
	desc = "This poster looks like an advertisement for tools, but is in fact a subliminal jab at the tools at CentCom."
	icon_state = "poster15"

/obj/structure/sign/poster/contraband/power
	name = "Power"
	desc = "A poster that positions the seat of power outside Nanotrasen."
	icon_state = "poster16"

/obj/structure/sign/poster/contraband/space_cube
	name = "Space Cube"
	desc = "Ignorant of Nature's Harmonic 6 Side Space Cube Creation, the Spacemen are Dumb, Educated Singularity Stupid and Evil."
	icon_state = "poster17"

/obj/structure/sign/poster/contraband/communist_state
	name = "Communist State"
	desc = "All hail the Communist party!"
	icon_state = "poster18"

/obj/structure/sign/poster/contraband/lamarr
	name = "Lamarr"
	desc = "This poster depicts Lamarr. Probably made by a traitorous Research Director."
	icon_state = "poster19"

/obj/structure/sign/poster/contraband/borg_fancy_1
	name = "Borg Fancy"
	desc = "An advertisement for the popular magazine of the same name."
	icon_state = "poster20"

/obj/structure/sign/poster/contraband/borg_fancy_2
	name = "Borg Fancy v2"
	desc = "Borg Fancy, Now only taking the most fancy."
	icon_state = "poster21"

/obj/structure/sign/poster/contraband/kss13
	name = "Kosmicheskaya Stantsiya 13 Does Not Exist"
	desc = "A poster mocking CentCom's denial of the existence of the derelict station near Space Station 13."
	icon_state = "poster22"

/obj/structure/sign/poster/contraband/rebels_unite
	name = "Rebels Unite"
	desc = "A poster urging the viewer to rebel against Nanotrasen."
	icon_state = "poster23"

/obj/structure/sign/poster/contraband/c20r
	// have fun seeing this poster in "spawn 'c20r'", admins...
	name = "C-20r"
	desc = "A poster advertising the Scarborough Arms C-20r."
	icon_state = "poster24"

/obj/structure/sign/poster/contraband/have_a_puff
	name = "Have a Puff"
	desc = "Who cares about lung cancer when you're high as a kite?"
	icon_state = "poster25"

/obj/structure/sign/poster/contraband/revolver
	name = "Revolver"
	desc = "Because seven shots are all you need."
	icon_state = "poster26"

/obj/structure/sign/poster/contraband/d_day_promo
	name = "D-Day Promo"
	desc = "A promotional poster for some rapper."
	icon_state = "poster27"

/obj/structure/sign/poster/contraband/syndicate_pistol
	name = "Syndicate Pistol"
	desc = "A poster advertising syndicate pistols as being 'classy as fuck'. It is covered in faded gang tags."
	icon_state = "poster28"

/obj/structure/sign/poster/contraband/energy_swords
	name = "Energy Swords"
	desc = "All the colors of the bloody murder rainbow."
	icon_state = "poster29"

/obj/structure/sign/poster/contraband/red_rum
	name = "Red Rum"
	desc = "Looking at this poster makes you want to kill."
	icon_state = "poster30"

/obj/structure/sign/poster/contraband/cc64k_ad
	name = "CC 64K Ad"
	desc = "The latest portable computer from Comrade Computing, with a whole 64kB of ram!"
	icon_state = "poster31"

/obj/structure/sign/poster/contraband/punch_shit
	name = "Punch Shit"
	desc = "Fight things for no reason, like a man!"
	icon_state = "poster32"

/obj/structure/sign/poster/contraband/the_griffin
	name = "The Griffin"
	desc = "The Griffin commands you to be the worst you can be. Will you?"
	icon_state = "poster33"

/obj/structure/sign/poster/contraband/lizard
	name = "Lizard"
	desc = "This lewd poster depicts a lizard preparing to mate."
	icon_state = "poster34"

/obj/structure/sign/poster/contraband/free_drone
	name = "Lost Drone"
	desc = "A faded missing poster looking for an outdated drone model. Wonder if the owner is still looking for it..."
	icon_state = "poster35"

/obj/structure/sign/poster/contraband/busty_backdoor_xeno_babes_6
	name = "Busty Backdoor Xeno Babes 6"
	desc = "Get a load, or give, of these all natural Xenos!"
	icon_state = "poster36"

/obj/structure/sign/poster/contraband/robust_softdrinks
	name = "Robust Softdrinks"
	desc = "Robust Softdrinks: More robust than a toolbox to the head!"
	icon_state = "poster37"

/obj/structure/sign/poster/contraband/shamblers_juice
	name = "Shambler's Juice"
	desc = "~Shake me up some of that Shambler's Juice!~"
	icon_state = "poster38"

/obj/structure/sign/poster/contraband/pwr_game
	name = "Pwr Game"
	desc = "The POWER that gamers CRAVE! In partnership with Vlad's Salad."
	icon_state = "poster39"

/obj/structure/sign/poster/contraband/starkist
	name = "Star-kist"
	desc = "Drink the stars!"
	icon_state = "poster40"

/obj/structure/sign/poster/contraband/space_cola
	name = "Space Cola"
	desc = "Your favorite cola, in space."
	icon_state = "poster41"

/obj/structure/sign/poster/contraband/space_up
	name = "Space-Up!"
	desc = "Sucked out into space by the FLAVOR!"
	icon_state = "poster42"

/obj/structure/sign/poster/contraband/kudzu
	name = "Kudzu"
	desc = "A poster advertising a movie about plants. How dangerous could they possibly be?"
	icon_state = "poster43"

/obj/structure/sign/poster/contraband/masked_men
	name = "Bumba"
	desc = "A poster advertising a movie about some masked men."
	icon_state = "poster44"

/obj/structure/sign/poster/contraband/buzzfuzz
	name = "Buzz Fuzz"
	desc = "A poster advertising the newest drink \"Buzz Fuzz\" with its iconic slogan of ~A Hive of Flavour~."
	icon_state = "poster45"

/obj/structure/sign/poster/contraband/scum
	name = "Security are Scum"
	desc = "Anti-security propaganda. Features a NanoTrasen security officer being shot in the head, with the words 'Scum' and a short inciteful manifesto. Used to anger security."
	icon_state = "poster46"

/obj/structure/sign/poster/contraband/syndicate_logo
	name = "Syndicate"
	desc = "A poster decipting a snake shaped into an ominous 'S'!"
	icon_state = "poster47"

/obj/structure/sign/poster/contraband/bountyhunters
	name = "Bounty Hunters"
	desc = "A poster advertising bounty hunting services. \"I hear you got a problem.\""
	icon_state = "poster48"


// 'Official' posters allowed by Nanotrasen

/obj/structure/sign/poster/official
	poster_item_name = "motivational poster"
	poster_item_desc = "An official Nanotrasen-issued poster to foster a compliant and obedient workforce. It comes with state-of-the-art adhesive backing, for easy pinning to any vertical surface."
	poster_item_icon_state = "rolled_legit"

/obj/structure/sign/poster/official/random
	name = "random official poster"
	random_basetype = /obj/structure/sign/poster/official
	icon_state = "random_official"
	never_random = TRUE

/obj/structure/sign/poster/official/here_for_your_safety
	name = "Here For Your Safety"
	desc = "A poster glorifying the station's security force."
	icon_state = "poster1_legit"

/obj/structure/sign/poster/official/nanotrasen_logo
	name = "Nanotrasen Logo"
	desc = "From transport, to defense - Nanotrasen is there."
	icon_state = "poster2_legit"

/obj/structure/sign/poster/official/cleanliness
	name = "Cleanliness"
	desc = "A poster warning of the dangers of poor hygiene."
	icon_state = "poster3_legit"

/obj/structure/sign/poster/official/help_others
	name = "Help Others"
	desc = "A poster encouraging you to help fellow crewmembers."
	icon_state = "poster4_legit"

/obj/structure/sign/poster/official/build
	name = "Build"
	desc = "A poster glorifying the engineering team."
	icon_state = "poster5_legit"

/obj/structure/sign/poster/official/bless_this_spess
	name = "Bless This Spess"
	desc = "A poster blessing this area."
	icon_state = "poster6_legit"

/obj/structure/sign/poster/official/science
	name = "Science"
	desc = "A poster depicting an atom."
	icon_state = "poster7_legit"

/obj/structure/sign/poster/official/ian
	name = "Ian"
	desc = "Arf arf. Yap."
	icon_state = "poster8_legit"

/obj/structure/sign/poster/official/obey
	name = "Obey"
	desc = "A poster instructing the viewer to obey authority."
	icon_state = "poster9_legit"

/obj/structure/sign/poster/official/walk
	name = "Walk"
	desc = "A poster instructing the viewer to walk instead of running."
	icon_state = "poster10_legit"

/obj/structure/sign/poster/official/state_laws
	name = "State Laws"
	desc = "Ionospheric interference is a constant threat! Ask your cyborgs and AIs to state laws!"
	icon_state = "poster11_legit"

/obj/structure/sign/poster/official/love_ian
	name = "Love Corgis!"
	desc = "Just because they're genetically engineered to be cute doesn't mean they're NOT cute!"
	icon_state = "poster12_legit"

/obj/structure/sign/poster/official/space_cops
	name = "Space Cops."
	desc = "A poster advertising the holovision show: Space Cops. Whatcha gonna do when they come for you?"
	icon_state = "poster13_legit"

/obj/structure/sign/poster/official/ue_no
	name = "Ue No."
	desc = "This thing is all in Neo-Kanji."
	icon_state = "poster14_legit"

/obj/structure/sign/poster/official/get_your_legs
	name = "Get Your LEGS"
	desc = "LEGS: Leadership, Experience, Genius, Subordination."
	icon_state = "poster15_legit"

/obj/structure/sign/poster/official/do_not_question
	name = "Do Not Question"
	desc = "A poster instructing the viewer not to ask about things they aren't meant to know."
	icon_state = "poster16_legit"

/obj/structure/sign/poster/official/work_for_a_future
	name = "Work For A Future"
	desc = "Even after The Collapse, we must forge onward."
	icon_state = "poster17_legit"

/obj/structure/sign/poster/official/soft_cap_pop_art
	name = "Soft Cap Pop Art"
	desc = "A poster reprint of some cheap pop art."
	icon_state = "poster18_legit"

/obj/structure/sign/poster/official/safety_internals
	name = "Safety: Internals"
	desc = "A poster instructing the viewer to wear internals in the rare environments where there is no oxygen or the air has been rendered toxic."
	icon_state = "poster19_legit"

/obj/structure/sign/poster/official/safety_eye_protection
	name = "Safety: Eye Protection"
	desc = "A poster instructing the viewer to wear eye protection when dealing with chemicals, smoke, or bright lights."
	icon_state = "poster20_legit"

/obj/structure/sign/poster/official/safety_report
	name = "Safety: Report"
	desc = "A poster instructing the viewer to report suspicious activity to the security force."
	icon_state = "poster21_legit"

/obj/structure/sign/poster/official/report_crimes
	name = "Report Crimes"
	desc = "A poster encouraging the swift reporting of crime or seditious behavior to station security."
	icon_state = "poster22_legit"

/obj/structure/sign/poster/official/ion_rifle
	name = "Ion Rifle"
	desc = "A poster displaying an Ion Rifle."
	icon_state = "poster23_legit"

/obj/structure/sign/poster/official/foam_force_ad
	name = "Foam Force Ad"
	desc = "Foam Force, it's Foam or be Foamed!"
	icon_state = "poster24_legit"

/obj/structure/sign/poster/official/cohiba_robusto_ad
	name = "Cohiba Robusto Ad"
	desc = "Cohiba Robusto, the classy cigar."
	icon_state = "poster25_legit"

/obj/structure/sign/poster/official/anniversary_vintage_reprint
	name = "50th Anniversary Vintage Reprint"
	desc = "A reprint of a poster from 2505, commemorating the 50th Anniversary of Nanoposters Manufacturing, a subsidiary of Nanotrasen."
	icon_state = "poster26_legit"

/obj/structure/sign/poster/official/fruit_bowl
	name = "Fruit Bowl"
	desc = " Simple, yet awe-inspiring."
	icon_state = "poster27_legit"

/obj/structure/sign/poster/official/pda_ad
	name = "PDA Ad"
	desc = "A poster advertising the latest PDA from Nanotrasen suppliers."
	icon_state = "poster28_legit"

/obj/structure/sign/poster/official/enlist // Instead of Death Squad, we're NT Navy
	name = "Enlist"
	desc = "Nanotrasen Naval Academy - Pilots wanted!"
	icon_state = "poster29_legit"

/obj/structure/sign/poster/official/nanomichi_ad
	name = "Nanomichi Ad"
	desc = " A poster advertising Nanomichi brand audio cassettes. Cutting edge audio recording!"
	icon_state = "poster30_legit"

/obj/structure/sign/poster/official/twelve_gauge
	name = "12 Gauge"
	desc = "A poster boasting about the superiority of 12 gauge shotgun shells; because they don't miss."
	icon_state = "poster31_legit"

/obj/structure/sign/poster/official/high_class_martini
	name = "High-Class Martini"
	desc = "Shake it, baby."
	icon_state = "poster32_legit"

/obj/structure/sign/poster/official/the_owl
	name = "The Owl"
	desc = "The Owl would do his best to protect the station. Will you?"
	icon_state = "poster33_legit"

/obj/structure/sign/poster/official/no_erp
	name = "No ERP"
	desc = "This poster reminds the crew that Eroticism, Rape, and Pornography are banned on Nanotrasen stations."
	icon_state = "poster34_legit"

/obj/structure/sign/poster/official/wtf_is_co2
	name = "Carbon Dioxide"
	desc = "CO2, best known for its fire/life-reducing properties."
	icon_state = "poster35_legit"

/obj/structure/sign/poster/official/spiderlings
	name = "Spiderlings"
	desc = "Report all sightings of Spiderlings! If left unchecked, they can overtake entire stations!"
	icon_state = "poster36_legit"

/obj/structure/sign/poster/official/duelshotgun
	name = "Cycler Shotgun Ad"
	desc = "A poster advertising an advanced dual magazine tube-shotgun, boasting about how easy it is to swap between the two tubes."
	icon_state = "poster37_legit"

/obj/structure/sign/poster/official/fashion
	name = "Fashion!"
	desc = "An advertisement for 'Fashion!', a popular fashion magazine. It depicts pretty woman with a fancy dress with a golden trim, she also has a red poppy in her hair."
	icon_state = "poster38_legit"

/obj/structure/sign/poster/official/pda_ad600
	name = "NT PDA600 Ad"
	desc = "A poster advertising an old discounted Nanotrasen PDA. This is the old 600 model, it has a small screen and suffered from security and networking issues."
	icon_state = "poster39_legit"

/obj/structure/sign/poster/official/pda_ad800
	name = "NT PDA800 Ad"
	desc = "An advertisement on an old Nanotrasen PDA model. The 800 fixed a lot of security flaws that the 600 had; it also had large touchscreen and hot-swappable cartridges."
	icon_state = "poster40_legit"

/obj/structure/sign/poster/official/hydro_ad
	name = "Hydroponics Tray"
	desc = "An advertisement for hydroponics trays. Space Station 13's botanical department uses a slightly newer model, but the principles are the same. From left to right: Green means the plant is done, red means the plant is unhealthy, flashing red means pests or weeds, yellow means the plant needs nutriment and blue means the plant needs water."
	icon_state = "poster41_legit"

/obj/structure/sign/poster/official/medical_green_cross
	name = "Medical"
	desc = "A green cross, one of the interplanetary symbol of health and aid. It has a bunch of common languages at the top with translations." // Keep it green, since the actual Red Cross is a trademarked symbol.
	icon_state = "poster42_legit"

/obj/structure/sign/poster/official/nt_storm_officer
	name = "NT Storm Ad"
	desc = "An advertisement for a NanoTrasen Paratrooper Division. This poster features an Officer's helmet."
	icon_state = "poster43_legit"

/obj/structure/sign/poster/official/nt_storm
	name = "NT Storm Ad"
	desc = "An advertisement for a NanoTrasen Paratrooper Division. This poster features a Private's helmet."
	icon_state = "poster44_legit"

// SKYRAT EDIT: More Posters.

/obj/structure/sign/poster/contraband/goldstar
	name = "Gold Star"
	desc = "A poster of a golden star."
	icon_state = "goldstar"

/obj/structure/sign/poster/contraband/panik
	name = "Don't Panic"
	desc = "A poster that tells you to not panic. It's not helping."
	icon_state = "bsposter10"

/obj/structure/sign/poster/contraband/lady1
	name = "Staring"
	desc = "A poster with an interesting woman on the front."
	icon_state = "bsposter12"

/obj/structure/sign/poster/contraband/sncrash
	name = "Crash"
	desc = "A poster that says Snow Crash."
	icon_state = "bsposter16"

/obj/structure/sign/poster/contraband/wintaaa
	name = "Winter"
	desc = "A poster advertising an old series... hold the door?"
	icon_state = "bsposter29"

/obj/structure/sign/poster/contraband/beach
	name = "Beach"
	desc = "A poster of a planet better than this rust-bucket."
	icon_state = "vgposter1"

/obj/structure/sign/poster/contraband/grilbeach
	name = "Beach"
	desc = "A poster of a sexy babe on a planet better than this rust-bucket."
	icon_state = "vgposter2"

/obj/structure/sign/poster/contraband/antifurry
	name = "Cat"
	desc = "A poster advocating for the removal of felinids."
	icon_state = "vgposter3"

/obj/structure/sign/poster/contraband/nukers
	name = "Nuke"
	desc = "A poster detailing how the nuke works... why is this here?!"
	icon_state = "vgposter4"

/obj/structure/sign/poster/contraband/apc
	name = "APC"
	desc = "A poster of an apc..."
	icon_state = "poster-apc"

/obj/structure/sign/poster/contraband/extinguisher
	name = "Fire Extinguisher"
	desc = "A poster of a fire extinguisher..."
	icon_state = "poster-extinguisher"

/obj/structure/sign/poster/contraband/nosmokers
	name = "No Smoking"
	desc = "A poster saying No Smoking."
	icon_state = "poster-nosmoking"

/obj/structure/sign/poster/contraband/hangers
	name = "Catgirls"
	desc = "A poster with a catgirl on it. Gross."
	icon_state = "poster113"

/obj/structure/sign/poster/contraband/earthhh
	name = "Terrasmokum Advertisment"
	desc = "A poster of Terra, advocating the benefits of smoking... asteroid moss?"
	icon_state = "poster115"

/obj/structure/sign/poster/contraband/billyh
	name = "Billy"
	desc = "A poster with depicting a muscular man."
	icon_state = "billyposter"

/obj/structure/sign/poster/contraband/billyh2
	name = "Billy"
	desc = "A poster depicting a muscular man in a seductive pose."
	icon_state = "billyposter2"

/obj/structure/sign/poster/contraband/ramranch
	name = "Robust Ranch"
	desc = "A sanctuary for lifting, rutting, and bucking. See you in the showers, cowboy."
	icon_state = "ramranch"

#undef PLACE_SPEED