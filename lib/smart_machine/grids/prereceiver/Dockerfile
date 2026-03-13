ARG SMARTMACHINE_VERSION

FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
LABEL maintainer="plainsource <plainsource@humanmind.me>"

# FCGI Essentials
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
	fcgiwrap \
	coreutils \
	util-linux \
	git \
	git-daemon-run \
	spawn-fcgi && \
    rm -rf /var/lib/apt/lists/*

CMD ["spawn-fcgi", "-n", "-p", "9000", "--", "/usr/sbin/fcgiwrap", "-f"]
