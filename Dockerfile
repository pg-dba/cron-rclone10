FROM rclone/rclone:latest

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN set -ex && \
# install bash
    apk add --no-cache bash && \
    apk add --no-cache tzdata && \
    apk add --no-cache linux-pam && \
    apk add --no-cache logrotate && \
    apk add --no-cache coreutils && \
    apk add --no-cache moreutils && \
    apk add --no-cache iputils-ping && \
    apk add --no-cache postgresql16-client && \
    apk add --no-cache pgbadger && \
    apk add --no-cache p7zip && \
    apk add --no-cache nano && \
    apk add --no-cache postfix && \
    apk add --no-cache mutt && \
    apk add --no-cache zabbix-utils && \
# making logging pipe
    mkfifo -m 0666 /var/log/cron.log && \
    ln -s /var/log/cron.log /var/log/crond.log && \
# buns
    echo "export PS1='[\u@\h] \t $ '" >> ~/.bashrc && \
    echo 'alias nocomments="sed -e :a -re '"'"'s/<\!--.*?-->//g;/<\!--/N;//ba'"'"' | sed -e :a -re '"'"'s/\/\*.*?\*\///g;/\/\*/N;//ba'"'"' | grep -v -P '"'"'^\s*(#|;|--|//|$)'"'"'"' >> ~/.bashrc

USER root

RUN wget --quiet https://dl.min.io/client/mc/release/linux-amd64/mc && chmod 700 mc && mv mc /usr/bin/

COPY main.cf /etc/postfix/main.cf
COPY start-cron /usr/sbin
RUN chmod 744 /usr/sbin/start-cron

# scripts for cron
COPY *.sh /etc/cron.d/
RUN chmod 755 /etc/cron.d/*.sh

# для send_pgbadger.sh
RUN mkdir -p /pglog
VOLUME /pglog

# для c_pgdump.sh
RUN mkdir -p /pgbackups
VOLUME /pgbackups

# redis dir
RUN mkdir -p /redis
VOLUME /redis

# для бэкапа redis
RUN mkdir -p /redisbackups
VOLUME /redisbackups

# для rclone sync
RUN mkdir -p /rclone-sync
VOLUME /rclone-sync

# для рабочий каталог для файлов tasks
RUN mkdir -p /cronwork
RUN chmod 777 /cronwork
VOLUME /cronwork

WORKDIR /etc/cron.d

ENTRYPOINT ["/etc/cron.d/docker-entrypoint.sh"]

#CMD ["start-cron -l 8 -L /cronwork/cron.log"]
CMD ["start-cron"]
