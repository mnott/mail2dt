#!/bin/bash

ROOTDIR=~/mail2dt
MAILUSR=mailuser
DTINBOX=~/Library/Application\ Support/DEVONthink/Inbox/
MAILDIR=$ROOTDIR/mail/$MAILUSR/Maildir/.Archive
CLEANUP=true
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

RESYNC_NEEDED=false
for src in new cur; do
	for i in $MAILDIR/$src/*; do
		if [[ $VERBOSE = true ]]; then
			echo "Working on file $i";
		fi
		FILE=$i;
		if [[ -f "$FILE" ]]; then
			TARGET="$(cat "$FILE" | docker exec --privileged -i "$CONTAINER_ID" perl /usr/local/bin/subject-decoder.pl)";
			if [[ $VERBOSE = true ]]; then echo $TARGET; fi
			# macOS filename limit is 255 BYTES per component. Reserve room for
			# ".eml" (4 B) plus up to ~45 collision dots → cap subject at 200 B.
			# Truncate by bytes, then drop a trailing partial UTF-8 sequence.
			max_bytes=200
			if (( $(printf '%s' "$TARGET" | wc -c) > max_bytes )); then
				TARGET=$(printf '%s' "$TARGET" | head -c "$max_bytes" | iconv -f UTF-8 -t UTF-8 -c)
			fi
			if [[ ! -f "$DTINBOX/$TARGET.eml" ]]; then
				cp -a "$FILE" "$DTINBOX/$TARGET.eml";
			else
				while [[ -f "$DTINBOX/${TARGET}.eml" ]]; do
					# Stop appending if name would exceed 250 bytes (replace instead).
					if (( $(printf '%s' "${TARGET}.eml" | wc -c) >= 250 )); then
						TARGET="${TARGET%?}."
					else
						TARGET="${TARGET}."
					fi
					# Hard safety: bail out if we can't find a free slot.
					[[ ${#TARGET} -gt 500 ]] && break
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
					RESYNC_NEEDED=true
				fi
			fi
		fi
	done
done

# Tell Dovecot the mails are gone so Apple Mail stops showing ghosts.
if [[ $RESYNC_NEEDED == true ]]; then
	if [[ $VERBOSE == true ]]; then echo "Resyncing Dovecot Archive index"; fi
	docker exec --privileged "$CONTAINER_ID" doveadm force-resync -u mnott Archive
fi

