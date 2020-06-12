#!/bin/bash

ROOTDIR=~/mail2dt
MAILUSR=mailuser
DTINBOX=~/Library/Application\ Support/DEVONthink\ 3/Inbox/
MAILDIR=$ROOTDIR/mail/$MAILUSR/Maildir
CLEANUP=false
VERBOSE=true

for src in new cur; do
	for i in $MAILDIR/$src/*; do
		FILE=$i;
		if [[ -f "$FILE" ]]; then
			TARGET="$(cat $FILE | $ROOTDIR/devonthink/subject-decoder.pl)";
			if [[ ! -f "$DTINBOX/$TARGET.eml" ]]; then
				cp -a "$FILE" "$DTINBOX/$TARGET.eml";
			else
				digit=1;
				while true; do
					temp_name="$TARGET-$digit";
					if [[ ! -f "$DTINBOX/$temp_name.eml" ]]; then
						cp -a "$FILE" "$DTINBOX/$temp_name.eml";
						TARGET="$temp_name";
						break;
					fi
				done
			fi
			if [[ -f "$DTINBOX/$TARGET.eml" ]]; then
				if [[ $VERBOSE == true ]]; then
					echo "Copied $TARGET";
				fi
				if [[ $CLEANUP == true ]]; then
					rm "$FILE";
				fi
			fi
		fi
	done
done

