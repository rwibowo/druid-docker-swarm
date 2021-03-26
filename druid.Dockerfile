FROM ubuntu:20.10

# Set version and home folder
ENV DRUID_VERSION=0.20.0
ENV DRUID_HOME=/opt/druid

# For Ubuntu 19.10 onward
RUN sed -i -e 's|disco|eoan|g' /etc/apt/sources.list
 
RUN mkdir -p /var/cache/oracle-jdk11-installer-local
COPY ./jdk-11.0.9_linux-x64_bin.tar.gz /var/cache/oracle-jdk11-installer-local/

# Java 8
RUN apt-get update \
    && apt-get install -y wget \
    && apt-get install -y software-properties-common \
    #&& apt-add-repository -y ppa:webupd8team/java \
    && apt-add-repository -y ppa:linuxuprising/java \
    && apt-get purge --auto-remove -y software-properties-common \
    && apt-get update \
    #&& echo oracle-java-8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
    && echo oracle-java11-installer-local shared/accepted-oracle-license-v1-2 select true | /usr/bin/debconf-set-selections \
    #&& apt-get install -y oracle-java8-installer \
    #&& apt-get install -y oracle-java8-set-default \
    && apt-get install -y oracle-java11-installer-local \
    && apt-get clean \
    #&& rm -rf /var/cache/oracle-jdk8-installer \
    && rm -rf /var/lib/apt/lists/*

# Druid system user
RUN adduser --system --group --no-create-home druid \
    && mkdir -p ${DRUID_HOME}

# Install Druid
WORKDIR /tmp
RUN wget https://archive.apache.org/dist/druid/${DRUID_VERSION}/apache-druid-${DRUID_VERSION}-bin.tar.gz
RUN cd /tmp; tar -xvf apache-druid-${DRUID_VERSION}-bin.tar.gz \
    && mv apache-druid-${DRUID_VERSION}/* ${DRUID_HOME} \
    && rm -fr ${DRUID_HOME}/conf-quickstart ${DRUID_HOME}/conf/* /tmp/* /var/tmp/*

# Install Druid extensions
WORKDIR ${DRUID_HOME}
RUN java -cp "lib/*" -Ddruid.extensions.directory="extensions" org.apache.druid.cli.Main tools pull-deps --no-default-hadoop -c "io.druid.extensions.contrib:druid-azure-extensions:0.12.3"

# Copy start script
COPY druid-entrypoint.sh ${DRUID_HOME}/druid-entrypoint.sh

RUN chmod +x ${DRUID_HOME}/druid-entrypoint.sh \
    && chown druid:druid -R ${DRUID_HOME}

# Expose ports:
# 8081 (Coordinator)
# 8082 (Broker)
# 8083 (Historical)
# 8088 (Router, if used)
# 8090 (Overlord)
# 8091, 8100–8199 (Druid Middle Manager; you may need higher than port 8199 if you have a very high druid.worker.capacity)
EXPOSE 8081
EXPOSE 8082
EXPOSE 8083
EXPOSE 8090
EXPOSE 8091 8100-8199

USER druid
WORKDIR ${DRUID_HOME}
ENTRYPOINT [ "./druid-entrypoint.sh" ]
