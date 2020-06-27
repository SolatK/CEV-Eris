
/client/verb/adminhelp(msg as text)
	set category = "Admin"
	set name = "Adminhelp"

	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "\red Speech is currently admin-disabled.")
		return

	//handle muting and automuting
	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, "<font color='red'>Error: Admin-PM: You cannot send adminhelps (Muted).</font>")
		return

	adminhelped = 1 //Determines if they get the message to reply by clicking the name.

	var/client/client = src
	var/datum/ticket/existing_ticket = get_open_ticket_by_client(client)
	if(!isnull(existing_ticket))
		to_chat(src, "<span class='notice'>You already have an open ticket! Either click a responding admin's name to reply, or <a href='?src=\ref[usr];close_ticket=\ref[existing_ticket]'>close your ticket</a> to start a new one.</span>")
		return



	if(src.handle_spam_prevention(msg,MUTE_ADMINHELP))
		return

	//clean the input msg
	if(!msg)
		return
	msg = sanitize(msg)
	if(!msg)
		return

	var/original_msg = msg


	if(!mob) //this doesn't happen
		return

	log_admin("HELP: [key_name(src)]: [msg]")

	// create ticket
	var/datum/ticket/ticket = new /datum/ticket(client)
	ticket.msgs += new /datum/ticket_msg(src.ckey, null, original_msg)

	var/mentor_msg = "<span class='notice'><b><font color=red>Request for Help: </font>[get_options_bar(mob, 4, 1, 1, 0, ticket)] (<a href='?_src_=holder;take_ticket=\ref[ticket]'>TAKE</a>) (<a href='?src=\ref[usr];close_ticket=\ref[ticket]'>CLOSE</a>):</b> [msg]</span>"
	msg = "<span class='notice'><b><font color=red>Request for Help:: </font>[get_options_bar(mob, 2, 1, 1, 1, ticket)] (<a href='?_src_=holder;take_ticket=\ref[ticket]'>TAKE</a>) (<a href='?src=\ref[usr];close_ticket=\ref[ticket]'>CLOSE</a>):</b> [msg]</span>"


	send2adminchat(key_name(src), original_msg)

	for(var/client/X in admins)
		if((R_ADMIN|R_MOD|R_MENTOR) & X.holder.rights)

			if(X.get_preference_value(/datum/client_preference/staff/play_adminhelp_ping) == GLOB.PREF_HEAR)
				X << 'sound/effects/adminhelp.ogg'
			if(X.holder.rights == R_MENTOR)
				to_chat(X, mentor_msg)		// Mentors won't see coloring of names on people with special_roles (Antags, etc.)
			else
				to_chat(X, msg)
	//show it to the person adminhelping too
	to_chat(src, "<font color='blue'>PM to-<b>Staff</b> (<a href='?src=\ref[usr];close_ticket=\ref[ticket]'>CLOSE</a>): [original_msg]</font>")

	return

