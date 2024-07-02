FROM alpine:edge

COPY repositories /etc/apk/repositories
RUN apk upgrade -a --no-cache
RUN apk add --no-cache \
	openrc busybox-openrc runit runit-openrc \
	git git-daemon-openrc stagit openssh-server \
	mini_httpd geomyidae@testing geomyidae-openrc@testing \
	tor tor-openrc
RUN apk add --no-cache i2pd i2pd-openrc \
	boost1.84-filesystem boost1.84-program_options \
	libcrypto3 libssl3

RUN apk add --no-cache make gcc libgit2-dev musl-dev
RUN git clone --depth 1 git://git.codemadness.org/stagit-gopher
RUN cd stagit-gopher && make && make install
RUN rm -rf stagit-gopher

# for running openrc
RUN printf '%s\n' 'rc_sys="docker"' 'rc_env_allow="*"' 'rc_provide="loopback net"' >> /etc/rc.conf
RUN sed -i 's/^tty/#&/' /etc/inittab

RUN sed -i '/^GITDAEMON_OPTS=/ { s|".*"|"--syslog --export-all --base-path=/git"| }' /etc/conf.d/git-daemon
RUN sed -i 's|^dir=.*|dir=/var/www| ; s|^nochroot$|chroot| ; /^#logfile=/ { s/^#// }' /etc/mini_httpd/mini_httpd.conf

RUN rm -r /var/www/*
RUN ln -s ./.blog/blog ./.blog/phlog ./.blog/data ./.blog/LICENSE /var/www/

COPY --chown=root:root --chmod=644 torrc /etc/tor/
RUN chown tor:nogroup /etc/tor/ /etc/i2pd/
COPY --chown=root:root --chmod=644 i2pd.conf tunnels.conf /etc/i2pd/
RUN chown i2pd:root /var/lib/tor/ /var/lib/i2pd/
COPY --chown=root:root --chmod=755 stagit.sh cloneblog.sh /etc/periodic/15min/
COPY authorized_keys /root/.ssh/

COPY sshd_config /etc/
RUN echo cfgfile=/etc/sshd_config >> /etc/conf.d/sshd

RUN adduser -D -H gopherd
COPY geomyidae.runit /etc/service/geomyidae-local/run
COPY geomyidae.runit /etc/service/geomyidae-tor/run
RUN printf '%s\n' HOST='$(cat /var/lib/tor/gitserv/hostname)' PORT=71 > /etc/service/geomyidae-tor/conf
COPY geomyidae.runit /etc/service/geomyidae-i2p/run
RUN printf '%s\n' HOST='$(basename /var/lib/i2pd/destinations/*.0.dat | cut -d . -f 1).b32.i2p' PORT=72 > /etc/service/geomyidae-i2p/conf

ENV SVCS="git-daemon sshd crond mini_httpd runitd i2pd tor"
RUN rc-update add syslog sysinit
RUN for svc in $SVCS; do rc-update add $svc default; done

CMD /sbin/init

