ARG BASE=quay.io/fedora/fedora-bootc:latest
FROM ${BASE}

COPY whitelist.txt blacklist.txt /tmp/swarf/
COPY build/ /tmp/swarf/build/

# Packages: remove and install in a single layer, so that files removed from
# the base image do not stay in an intermediate layer.
# Local builds may mount a package cache on /var/cache/libdnf5 (podman build -v).
RUN bash /tmp/swarf/build/packages.sh /tmp/swarf/whitelist.txt /tmp/swarf/blacklist.txt

COPY system/ /

RUN bash /tmp/swarf/build/configure.sh && rm -rf /tmp/swarf

RUN bootc container lint
