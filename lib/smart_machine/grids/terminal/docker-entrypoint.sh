#!/bin/bash
set -e

# sshd
service rsyslog start && service ssh start

# fail2ban
fail2ban-client start

# haproxy
#haproxy -W -db -f /etc/haproxy/haproxy.cfg

# initial setup
if [ ! -e /run/initial_container_start ]; then
    touch /run/initial_container_start

    # user
    if ! id -u ${USERNAME} >/dev/null 2>&1; then
	adduser --quiet --gecos "" --disabled-login ${USERNAME}
	adduser --quiet ${USERNAME} sudo
	echo "${USERNAME}:${PASSWORD}" | chpasswd
    fi

    # ssh keys
    # TODO: Change CONTAINER_NAME to `hostname` when hostname has been set to CONTAINER_NAME inside the container.
    if [ ! -d /home/${USERNAME}/.ssh ]; then
	mkdir -p /home/${USERNAME}/.ssh && \
	    ssh-keygen -b 4096 -q -f /home/${USERNAME}/.ssh/id_rsa -N "" -C "${USERNAME}@${CONTAINER_NAME}" && \
	    touch /home/${USERNAME}/.ssh/authorized_keys && \
	    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.ssh && \
	    chmod -R 700 /home/${USERNAME}/.ssh && chmod 600 /home/${USERNAME}/.ssh/*
    fi

    # emacs
    if [ ! -d /home/${USERNAME}/.emacs.d ]; then
	mkdir -p /home/${USERNAME}/.emacs.d && \
	    cp /root/.emacs.d/* /home/${USERNAME}/.emacs.d && \
	    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.emacs.d
    fi

    # apt-get
    apt-get update -qq

    # packages
    if [ -n "${PACKAGES}" ]; then
	apt-get install -y --no-install-recommends ${PACKAGES}
    fi

    # env
    unset CONTAINER_NAME PACKAGES USERNAME PASSWORD

    echo "Initial setup complete."
fi

exec "$@"
