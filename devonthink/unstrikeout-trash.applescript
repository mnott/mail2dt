-- Moves the direct children of a database's Trash into a regular group at the
-- database root. DEVONthink renders every name inside the trash with a
-- strike-through and that cannot be styled away; outside the trash names read
-- normally again. Groups move as a whole (subtree comes along), so the trash's
-- inner structure is preserved.
--
-- Save it as .scpt (don't forget to set dryRun to false), and put it into
-- the scripts subfolder of DTP. Then you can add it to the toolbar.

property targetDatabaseName : "" -- "" = current database, otherwise a database name
property targetGroupName : "Deleted Mail" -- group at the database root, created if missing
property dryRun : true -- true: log what would be moved, change nothing

on run
	tell application id "DNtp"
		set theDatabase to current database
		if targetDatabaseName is not "" then set theDatabase to database targetDatabaseName
		
		-- create location is get-or-create, but it writes, so the dry run skips it
		set destGroup to missing value
		if not dryRun then set destGroup to create location ("/" & targetGroupName) in theDatabase
		
		set theItems to every child of trash group of theDatabase -- snapshot: direct children only
		set reportText to ""
		set movedCount to 0
		repeat with r in theItems
			if dryRun then
				set lineText to "would move: " & (name of r) & " [" & (kind of r)
				if record type of r is group then set lineText to lineText & ", " & (count of children of r) & " children"
				set lineText to lineText & "]"
				log lineText
				set reportText to reportText & lineText & linefeed
			else
				move record r to destGroup
			end if
			set movedCount to movedCount + 1
		end repeat
		
		if dryRun then
			return reportText & "DRY RUN: " & movedCount & " items would be moved to \"" & targetGroupName & "\" in \"" & (name of theDatabase) & "\""
		else
			return (movedCount as rich text) & " items moved to \"" & targetGroupName & "\" in \"" & (name of theDatabase) & "\""
		end if
	end tell
end run
