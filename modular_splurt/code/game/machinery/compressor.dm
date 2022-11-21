/obj/machinery/compressor
	name = "\improper Automatic Robotic Factory 5000"
	desc = "Edit Two"
	icon = 'icons/obj/recycling.dmi'
	icon_state = "separator-AO1"
	layer = ABOVE_ALL_MOB_LAYER // Overhead
	density = FALSE
	var/transform_dead = 0
	var/transform_standing = 1
	var/cooldown_duration = 200 // 1 minute
	var/cooldown = 0
	var/cooldown_timer
	var/obj/effect/countdown/transformer/countdown
	var/mob/living/silicon/ai/masterAI

/obj/machinery/compressor/Initialize(mapload)
	// On us
	. = ..()
	new /obj/machinery/conveyor/auto(locate(x - 1, y, z), WEST)
	new /obj/machinery/conveyor/auto(loc, WEST)
	new /obj/machinery/conveyor/auto(locate(x + 1, y, z), WEST)
	countdown = new(src)
	countdown.start()

/obj/machinery/compressor/examine(mob/user)
	. = ..()
	if(cooldown || isobserver(user))
		. += "It will be ready in [DisplayTimeText(cooldown_timer - world.time)]."

/obj/machinery/compressor/Destroy()
	QDEL_NULL(countdown)
	. = ..()

/obj/machinery/compressor/power_change()
	..()
	update_icon()

/obj/machinery/compressor/update_icon_state()
	if(stat & (BROKEN|NOPOWER) || cooldown == 1)
		icon_state = "separator-AO0"
	else
		icon_state = initial(icon_state)

/obj/machinery/compressor/Bumped(atom/movable/AM)
	if(cooldown == 1)
		return

	// Crossed didn't like people lying down.
	if(ishuman(AM))
		// Only humans can enter from the west side, while lying down.
		var/move_dir = get_dir(loc, AM.loc)
		var/mob/living/carbon/human/H = AM
		if((transform_standing || H.lying) && move_dir == EAST)// || move_dir == WEST)
			AM.forceMove(drop_location())
			do_transform(AM)

/obj/machinery/compressor/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	// Allows items to go through,
	// to stop them from blocking the conveyor belt.
	if(!ishuman(mover))
		if(get_dir(src, mover) == EAST)
			return
	return FALSE

/obj/machinery/compressor/process()
	if(cooldown && (cooldown_timer <= world.time))
		cooldown = FALSE
		update_icon()

/obj/machinery/compressor/proc/do_transform(mob/living/carbon/human/H)
	if(stat & (BROKEN|NOPOWER))
		return
	if(cooldown == 1)
		return

	if(!transform_dead && H.stat == DEAD)
		playsound(src.loc, 'sound/machines/buzz-sigh.ogg', 50, 0)
		return

	// Activate the cooldown
	cooldown = 1
	cooldown_timer = world.time + cooldown_duration
	update_icon()

	playsound(src.loc, 'sound/items/welder.ogg', 50, 1)
	//H.emote("scream") // It is painful
	//H.adjustBruteLoss(max(0, 80 - H.getBruteLoss())) // Hurt the human, don't try to kill them though.

	// Sleep for a couple of ticks to allow the human to see the pain
	//sleep(5)

	use_power(5000) // Use a lot of power
	var/obj/item/fleshlight/F = new/obj/item/fleshlight(src)
	H.forceMove(F)