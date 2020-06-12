FROM alpine:3.7
RUN apk -U add dovecot shadow bash

RUN mkdir /mail && mkdir /config

COPY root/ /

RUN chmod 755 /usr/local/bin/log

CMD /run.sh BACKGROUND

