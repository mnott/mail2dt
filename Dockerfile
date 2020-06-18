FROM alpine:3.7
# Adding environment variables for TZ
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk -U add perl dovecot shadow bash make

RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'inc::latest')"
RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'MIME::Base64')"
RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'URI::Encode')"
RUN perl -MCPAN -e "CPAN::Shell->notest('install', 'URI::Escape')"

RUN mkdir /mail && mkdir /config

COPY root/ /

RUN chmod 755 /usr/local/bin/log

CMD /run.sh BACKGROUND

