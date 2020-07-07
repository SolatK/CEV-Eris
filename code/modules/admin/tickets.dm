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


/datum/ticket/proc/get_data()
	var/data
	for(var/datum/ticket_msg/message in msgs)
		data += "[message.msg_from] to [message.msg_to]: [message.msg]\n"
	return data


/client/verb/view_tickets()
	set name = "View Tickets"
	set category = "Admin"
	var/datum/browser/panel = new(usr, "tickets", "tickets", 500, 500)
	generate_ui(panel)



/client/proc/generate_ui(var/datum/browser/panel, var/datum/ticket/selected)
	var/output = {"
	<div class='container'>
	<table border='1'>
	<tr>
	<div width='33%' float='left'>
		<table border='1'>
			<tr>
				<th>Player:</th>
				<th>Admins:</th>
				<th>options:</th>
			</tr>"}
	for(var/datum/ticket/ticket in tickets)
		output += {"
			<tr>
				<th>[ticket.owner]</th>
				<th>[jointext(ticket.assigned_admins, ", ")]</th>
				<th><a href='?src=\ref[src];ticket=open_ticket;ticket_src=\ref[ticket];panel_src=\ref[panel]'>open</a>/<a href='?src=\ref[usr];close_ticket=\ref[ticket]'>close</a>/<a href='?src=\ref[src];ticket=join'>join</a></th>
			</tr>"}
	output += "</table>"
	output += "<th>"
	if(selected)
		output += selected.get_data()
	panel.set_content(output)
	ticket_panels += panel
	panel.open()
