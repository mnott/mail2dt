#!/bin/sh

die () {
  echo >&2 "$@"
  exit 1
}

syslogd

PUID=${PUID:-3050}
PGID=${PGID:-3050}

id dovecot 2>/dev/null
[ ! $? -eq 0 ] && addgroup -g $PGID dovecot && adduser -u $PUID -G dovecot -D -s /bin/sh dovecot

#if [ ! "$(id -u dovecot)" -eq "$PUID" ]; then usermod -o -u "$PUID" dovecot ; fi
#if [ ! "$(id -g dovecot)" -eq "$PGID" ]; then groupmod -o -g "$PGID" dovecot ; fi

chown -R dovecot:dovecot /config
chown dovecot:dovecot /mail
chmod +x /mail

if [ -f "/mail/dovecot.passwd" ]; then
  cp /mail/dovecot.passwd /config
fi

if [ ! -f "/config/dovecot.passwd" ]; then
  die "/config/dovecot.passwd does not exist - please create it. an example:
  (username):(password with scheme):(uid):(gid)::(virtual home folder)
  user:{plain}password:1050:1050::/mail/user"
fi

/usr/sbin/dovecot
tail -f /var/log/messages
