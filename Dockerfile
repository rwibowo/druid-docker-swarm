
FROM maven:3-jdk-8-slim as builder

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get -qq update \
    && apt-get -qq -y install --no-install-recommends python3 python3-yaml

ENV VERSION=0.20.0
ENV DRUID_HOME=/opt/druid

# Install Druid
WORKDIR /opt
RUN curl -O https://archive.apache.org/dist/druid/${VERSION}/apache-druid-${VERSION}-bin.tar.gz \
    && tar -xvf apache-druid-${VERSION}-bin.tar.gz -C /opt \
    && ln -s /opt/apache-druid-${VERSION} /opt/druid 
 
FROM amd64/busybox:1.30.0-glibc as busybox

FROM gcr.io/distroless/java:8
LABEL maintainer="Apache Druid Developers <dev@druid.apache.org>"

COPY --from=busybox /bin/busybox /busybox/busybox
RUN ["/busybox/busybox", "--install", "/bin"]

RUN addgroup -S -g 1000 druid \
 && adduser -S -u 1000 -D -H -h /opt/druid -s /bin/sh -g '' -G druid druid \
 && mkdir -p /opt/druid/var \
 && chmod 775 /opt/druid/var \
 && chown -R druid:druid /opt/druid/var

COPY --chown=druid:druid --from=builder /opt /opt
COPY ./druid.sh /druid.sh
RUN chmod 775 /druid.sh

USER druid
WORKDIR /opt/druid

ENTRYPOINT ["/druid.sh"]
