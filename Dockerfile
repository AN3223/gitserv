FROM alpine

COPY repositories /etc/apk/repositories
RUN apk add --no-cache \
	openrc busybox-initscripts runit runit-openrc \
	git git-daemon-openrc stagit openssh-server \
	mini_httpd geomyidae@testing geomyidae-openrc@testing \
	tor tor-openrc
RUN apk add --no-cache i2pd@edgecommunity i2pd-openrc@edgecommunity \
	boost1.77-filesystem@edge boost1.77-program_options@edge

RUN apk add --no-cache make tcc@testing libgit2-dev musl-dev
RUN git clone --depth 1 git://git.codemadness.org/stagit-gopher
RUN cd stagit-gopher && make CC=tcc && make install
RUN rm -rf stagit-gopher

# for running openrc
RUN printf '%s\n' 'rc_sys="docker"' 'rc_env_allow="*"' 'rc_provide="loopback net"' >> /etc/rc.conf
RUN sed -i 's/^tty/#&/' /etc/inittab

RUN sed -i '/^GITDAEMON_OPTS=/ { s|".*"|"--syslog --export-all --base-path=/git"| }' /etc/conf.d/git-daemon
RUN sed -i 's|^dir=.*|dir=/var/www| ; s|^nochroot$|chroot| ; /^#logfile=/ { s/^#// }' /etc/mini_httpd/mini_httpd.conf

RUN rm -r /var/www/*
RUN ln -s ./.blog/blog ./.blog/phlog ./.blog/data ./.blog/LICENSE /var/www/

RUN passwd -u root # for ssh

COPY torrc /etc/tor/
COPY i2pd.conf tunnels.conf /etc/i2pd/
COPY stagit.sh cloneblog.sh /etc/periodic/15min/
COPY populate.runit /etc/service/populate/run
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

