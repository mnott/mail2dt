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
		if [[ $VERBOSE = true ]]; then
			echo "Working on file $i";
		fi
		FILE=$i;
		if [[ -f "$FILE" ]]; then
			TARGET="$(cat $FILE | docker exec --privileged -i $CONTAINER_ID perl /usr/local/bin/subject-decoder.pl)";
			if [[ $VERBOSE = true ]]; then echo $TARGET; fi
			if [[ ! -f "$DTINBOX/$TARGET.eml" ]]; then
				cp -a "$FILE" "$DTINBOX/$TARGET.eml";
			else
				while [[ -f "$DTINBOX/${TARGET}.eml" ]]; do
					TARGET="${TARGET}."
				done
				if [[ ! -f "$DTINBOX/$TARGET.eml" ]]; then
					if [[ $VERBOSE = true ]]; then echo $TARGET; fi
					cp -a "$FILE" "$DTINBOX/$TARGET.eml";
				fi
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

