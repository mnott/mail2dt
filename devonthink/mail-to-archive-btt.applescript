-- Move every selected message in Apple Mail into "Archive" of the "Devonthink" account,
-- then leave the following message selected (like pressing the down arrow).
-- Uses raw Apple event codes so it compiles anywhere, even where Mail's
-- dictionary is not available to the compiler (e.g. pasted into BetterTouchTool).
--   «class mbxp» = mailbox, «class mact» = account, «property slct» = selection,
--   «event coremove» = move, «class insh» = "to" parameter of move
--
-- Order matters: the selection is captured, the down arrow is pressed so the
-- list selection advances to the next message, and only then are the captured
-- messages moved. Mail's "visible messages" property is unusable (error -10000),
-- so the row position cannot be tracked by script.
--
-- When triggered by a shortcut with a modifier (e.g. Ctrl+A) the modifier is
-- still held when the keystroke is sent, turning Down into Ctrl+Down. So the
-- script waits (up to 1 s) until Shift, Control, Option and Command are released.

use framework "AppKit"
use scripting additions

on modifiersDown()
	set flags to (current application's NSEvent's modifierFlags()) as integer
	-- bits 17..20 = shift, control, option, command (bit 16, caps lock, ignored)
	return ((flags div 131072) mod 16) is not 0
end modifiersDown

set accountName to "Devonthink"
set mailboxName to "Archive"

tell application "Mail"
	set targetBox to «class mbxp» mailboxName of «class mact» accountName
	set selectedMessages to «property slct»
	if (count of selectedMessages) is 0 then
		display notification "No messages selected." with title "Mail → Archive"
		return
	end if
	activate
end tell

-- Wait for the trigger's modifier keys to be released, then advance the selection.
set waited to 0
repeat while modifiersDown() and waited < 20
	delay 0.05
	set waited to waited + 1
end repeat
-- Also let the trigger key itself (e.g. F1) come back up and Mail settle a
-- fresh multi-selection before the arrow key arrives.
delay 0.2
tell application "System Events" to key code 125
delay 0.2

tell application "Mail"
	set moved to 0
	repeat with aMessage in selectedMessages
		«event coremove» aMessage given «class insh»:targetBox
		set moved to moved + 1
	end repeat
	display notification (moved as text) & " message(s) moved to " & accountName & "/" & mailboxName with title "Mail → Archive"
end tell
