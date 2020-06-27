/datum/ticket
	var/client/owner
	var/list/assigned_admins = list()
	var/status = TICKET_OPEN
	var/list/msgs = list()
	var/client/closed_by

/datum/ticket/New(var/client/owner)
	src.owner = owner
	tickets |= src

/datum/ticket/proc/close(var/client/closed_by)
	if(status == TICKET_CLOSED)
		return

	if(status == TICKET_ASSIGNED && !(closed_by.ckey in assigned_admin_ckeys() || owner.ckey == closed_by.ckey) && alert(closed_by, "You are not assigned to this ticket. Are you sure you want to close it?",  "Close ticket?" , "Yes" , "No") != "Yes")
		return

	src.status = TICKET_CLOSED
	src.closed_by = closed_by

	to_chat(src.owner, "<span class='notice'><b>Your ticket has been closed by [closed_by.ckey].</b></span>")
	send2adminirc("[key_name(src.owner)]'s ticket has been closed by [key_name(closed_by)].")

	return 1

/datum/ticket/proc/take(var/client/assigned_admin)
	if(status == TICKET_CLOSED)
		return

	if(status == TICKET_ASSIGNED && (assigned_admin.ckey in assigned_admin_ckeys() || alert(assigned_admin, "This ticket is already assigned. Do you want to add yourself to the ticket?",  "Join ticket?" , "Yes" , "No") != "Yes"))
		return

	if(assigned_admin.ckey == owner.ckey)
		return

	assigned_admins |= assigned_admin
	src.status = TICKET_ASSIGNED

	send2adminirc("[key_name(assigned_admin)] has assigned themself to [key_name(src.owner)]'s ticket.")
	to_chat(src.owner, "<span class='notice'><b>[assigned_admin.ckey] has added themself to your ticket and should respond shortly. Thanks for your patience!</b></span>")

	return 1

/datum/ticket/proc/assigned_admin_ckeys()
	. = list()

	for(var/client/assigned_admin in assigned_admins)
		. |= assigned_admin.ckey

proc/get_open_ticket_by_client(var/client/owner)
	for(var/datum/ticket/ticket in tickets)
		if(ticket.owner == owner && (ticket.status == TICKET_OPEN || ticket.status == TICKET_ASSIGNED))
			return ticket // there should only be one open ticket by a client at a time, so no need to keep looking

/datum/ticket_msg
	var/msg_from
	var/msg_to
	var/msg

/datum/ticket_msg/New(var/msg_from, var/msg_to, var/msg)
	src.msg_from = msg_from
	src.msg_to = msg_to
	src.msg = msg

/datum/ticket_panel
	var/datum/ticket/open_ticket = null

/datum/ticket_panel/tg_ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = 0, datum/tgui/master_ui = null, datum/ui_state/state = tg_always_state)
	ui = tgui_process.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "ticket_panel", "Ticket Manager", 600, 800, master_ui, state)
		ui.open()

/datum/ticket_panel/ui_data(mob/user)
	var/list/data = list()

	data["may_take_ticket"] = user.client.holder
	data["tickets"] = list()
	data["messages"] = list()

	for(var/id = tickets.len, id >= 1, id--)
		var/datum/ticket/ticket = tickets[id]
		if(user.client.holder || ticket.owner == user)
			var/open = 0
			var/status = "Unknown status"
			switch(ticket.status)
				if(TICKET_OPEN)
					open = 1
					status = "Open, unassigned"
				if(TICKET_ASSIGNED)
					open = 1
					status = "Assigned to [english_list(ticket.assigned_admin_ckeys(), "no one")]"
				if(TICKET_CLOSED)
					status = "Closed by [ticket.closed_by.ckey]."
			data["tickets"] += list(list("id" = id, "owner" = ticket.owner.ckey, "open" = open, "status" = status))

	if(open_ticket)
		for(var/datum/ticket_msg/msg in open_ticket.msgs)
			var/msg_to = msg.msg_to ? msg.msg_to : "Adminhelp"
			data["messages"] += list(list("msg_from" = msg.msg_from, "msg_to" = msg_to, "msg" = msg.msg))

	return data

/datum/ticket_panel/ui_act(action, params)
	if(..())
		return

	var/datum/ticket/ticket = tickets[text2num(params["id"])]
	if(!ticket)
		return

	switch(action)
		if("view")
			open_ticket = ticket
			return 1
		if("take")
			return ticket.take(usr.client)
		if("close")
			return ticket.close(usr.client)


/client/verb/view_tickets()
	set name = "View Tickets"
	set category = "Admin"

	var/datum/ticket_panel/ticket_panel = src.get_ticket_panel()
	ticket_panel.tg_ui_interact(src.mob)

/client/proc/get_ticket_panel()
	. = ticket_panels[src.ckey]

	if(!.)
		. = new /datum/ticket_panel()
		ticket_panels[src.ckey] = .