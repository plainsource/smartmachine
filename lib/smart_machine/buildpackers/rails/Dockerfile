ARG SMARTMACHINE_VERSION

FROM smartmachine/smartengine:$SMARTMACHINE_VERSION
LABEL maintainer="plainsource <plainsource@humanmind.me>"

# Ruby on Rails Essentials
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
	tzdata \
	nodejs \
	yarn \
	libmariadb-dev \
	libvips42 \
	ffmpeg \
	mupdf \
	mupdf-tools \
	poppler-utils && \
    rm -rf /var/lib/apt/lists/* && \
    gem install bundler -v 2.1.4

CMD ["smartmachine", "buildpacker", "packer", "rails"]
