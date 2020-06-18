#!/bin/bash

ROOTDIR=~/mail2dt
MAILUSR=mailuser
DTINBOX=~/Library/Application\ Support/DEVONthink\ 3/Inbox/
MAILDIR=$ROOTDIR/mail/$MAILUSR/Maildir
CLEANUP=false
VERBOSE=true

export PATH=/usr/local/bin/:$PATH

CONTAINER_NAME=mail2dt
CONTAINER_ID=$(docker container ls | grep $CONTAINER_NAME | cut -d" " -f1)

if [[ $CONTAINER_ID == "" ]]; then
	echo Cannot find Docker Container.
	exit 1
fi

if [[ $VERBOSE == true ]]; then
	echo Using Docker Container $CONTAINER_ID
fi

for src in new cur; do
	for i in $MAILDIR/$src/*; do
		FILE=$i;
		if [[ -f "$FILE" ]]; then
			TARGET="$(cat $FILE | docker exec --privileged -i $CONTAINER_ID perl /usr/local/bin/subject-decoder.pl)";
			if [[ ! -f "$DTINBOX/$TARGET.eml" ]]; then
				cp -a "$FILE" "$DTINBOX/$TARGET.eml";
			else
				while true; do
					temp_name="${TARGET}.";
					if [[ ! -f "$DTINBOX/$temp_name.eml" ]]; then
						if [[ "$temp_name" == "-1" ]]; then break; fi;
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

