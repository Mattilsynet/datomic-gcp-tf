FROM clojure:temurin-21-tools-deps-1.11.3.1456-jammy
ARG datomic_version=1.0.7075

ENV DATOMIC_VERSION $datomic_version
ENV DATOMIC_HOME /opt/datomic-pro-$datomic_version

RUN apt-get update && apt-get install -y unzip && apt-get install -y wget

RUN wget https://datomic-pro-downloads.s3.amazonaws.com/${DATOMIC_VERSION}/datomic-pro-${DATOMIC_VERSION}.zip -O /tmp/datomic.zip \
  && unzip /tmp/datomic.zip -d /opt \
  && rm -f /tmp/datomic.zip

WORKDIR $DATOMIC_HOME
RUN echo DATOMIC HOME: $DATOMIC_HOME

VOLUME /etc/datomic
VOLUME /log

ENTRYPOINT ["./bin/transactor", "-Xmx4g", "-Xms4g", "-Ddatomic.printConnectionInfo=true", "/etc/datomic/transactor.properties"]
