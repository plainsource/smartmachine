FROM ruby:2.7.7-bullseye
LABEL maintainer="plainsource <plainsource@humanmind.me>"

# User
# --- Fix to change docker gid to 998 (if it is in use) so that addgroup is free to create a group with docker gid.
ARG USER_NAME
ARG USER_UID
ARG DOCKER_GID
ARG DOCKER_GNAME
RUN sed -i "s/$DOCKER_GID/998/" /etc/group && \
	adduser --disabled-password --gecos "" --uid "$USER_UID" "$USER_NAME" && \
	addgroup --gid "$DOCKER_GID" "$DOCKER_GNAME" && adduser "$USER_NAME" "$DOCKER_GNAME"

# Add Docker Repository for Debian
RUN apt-get update && apt-get install -y --no-install-recommends lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update

# Essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
	docker-ce-cli \
	rsync \
    && rm -rf /var/lib/apt/lists/*

# smartmachine gem
ARG SMARTMACHINE_VERSION
COPY ./smartmachine-$SMARTMACHINE_VERSION.gem ./smartmachine-$SMARTMACHINE_VERSION.gem
RUN gem install --no-document ./smartmachine-$SMARTMACHINE_VERSION.gem && \
	rm ./smartmachine-$SMARTMACHINE_VERSION.gem

# smartmachine master key
ARG SMARTMACHINE_MASTER_KEY
ENV SMARTMACHINE_MASTER_KEY=$SMARTMACHINE_MASTER_KEY
