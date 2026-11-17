on run
	-- Smart rule names, one per line, from ~/mail2dt/config/smartrules.txt
	-- (gitignored; see smartrules.txt.example). Lines starting with # are ignored.
	set ruleFile to (POSIX path of (path to home folder)) & "mail2dt/config/smartrules.txt"
	set ruleList to {}
	try
		set ruleList to paragraphs of (do shell script "grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' " & quoted form of ruleFile)
	end try
	set inboxFolder to (POSIX path of (path to application support folder from user domain)) & "DEVONthink 3/Inbox/"
	
	tell application id "DNtp"
		activate
		show progress indicator "Archiving Mails…" steps ((count of ruleList) + 4) with cancel button
		step progress indicator "Importing Mails..."
	end tell
	
	-- Run OUTSIDE the tell block: inside it, DEVONthink itself executes the shell
	-- script / delays, its main thread is blocked and it cannot import meanwhile.
	do shell script "~/mail2dt/devonthink/mail2devonthink.sh"
	
	-- Wait until DEVONthink has picked up every (visible) file from its Inbox folder.
	tell application id "DNtp" to step progress indicator "Waiting for DEVONthink import..."
	set waited to 0
	repeat
		set n to (do shell script "find " & quoted form of inboxFolder & " -maxdepth 1 -type f ! -name '.*' ! -name 'Icon?' | wc -l") as integer
		if n = 0 then exit repeat
		if waited ≥ 600 then
			tell application id "DNtp" to hide progress indicator
			error "DEVONthink did not finish importing (" & n & " files left in Inbox folder)."
		end if
		delay 2
		set waited to waited + 2
	end repeat
	delay 3
	
	tell application id "DNtp"
		step progress indicator "Deduplicating..."
		set inboxUUID to uuid of inbox
		set dbList to every database
		set itemList to children of incoming group
		repeat with j from 1 to count of itemList
			set theItem to item j of itemList
			if (type of theItem is not group) and (type of theItem is not smart group) then
				set isDup to (number of duplicates of theItem > 0)
				-- Emails use their Message-ID as UUID. If another database already has
				-- it, a smart rule can't move it there ("UUID already in database").
				if not isDup then
					set u to uuid of theItem
					repeat with i from 1 to count of dbList
						set d to item i of dbList
						if (uuid of d) is not inboxUUID then
							if (get record with uuid u in d) is not missing value then
								set isDup to true
								exit repeat
							end if
						end if
					end repeat
				end if
				if isDup then move record theItem to trash group of (database of theItem)
			end if
		end repeat
	end tell
	
	set ruleErrors to {}
	delay 1
	repeat with rule in ruleList
		set ruleName to rule as text
		tell application id "DNtp"
			step progress indicator ruleName
			try
				with timeout of 3600 seconds
					perform smart rule name ruleName
				end timeout
			on error errMsg
				set end of ruleErrors to ruleName & ": " & errMsg
			end try
		end tell
	end repeat

	-- Fallback: mails the rules left behind, e.g. received as BCC, where your
	-- address is only in the delivery headers that smart rules cannot see.
	-- route-mail.pl maps them via config/routes.txt (gitignored, see .example).
	set homePath to POSIX path of (path to home folder)
	set routeFile to homePath & "mail2dt/config/routes.txt"
	set router to homePath & "mail2dt/devonthink/route-mail.pl"
	tell application id "DNtp"
		step progress indicator "Routing remaining mails..."
		set itemList to children of incoming group
	end tell
	repeat with j from 1 to count of itemList
		set theItem to item j of itemList
		tell application id "DNtp"
			set isMail to (type of theItem is not group) and (type of theItem is not smart group) and ((filename of theItem) ends with ".eml")
			if isMail then set p to path of theItem
		end tell
		if isMail then
			-- shell call outside the tell block (see above)
			set t to ""
			try
				set t to do shell script "/usr/bin/perl " & quoted form of router & " " & quoted form of routeFile & " " & quoted form of p
			end try
			if t is not "" then
				tell application id "DNtp"
					set targetGroup to get record with uuid t
					if targetGroup is missing value then
						set end of ruleErrors to "routes.txt: no group with UUID " & t
					else
						try
							move record theItem to targetGroup
						on error errMsg
							set end of ruleErrors to (name of theItem) & ": " & errMsg
						end try
					end if
				end tell
			end if
		end if
	end repeat
	tell application id "DNtp" to hide progress indicator

	if ruleErrors is not {} then
		set AppleScript's text item delimiters to return
		set msg to ruleErrors as text
		set AppleScript's text item delimiters to ""
		tell application id "DNtp" to display alert "Archive Mails: some rules failed" message msg
	end if
end run
