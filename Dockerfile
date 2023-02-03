#FROM openjdk:8-jre-alpine
FROM container-registry.oracle.com/java/jdk:17.0.3-oraclelinux8
LABEL maintainer="Ranjith Vijayan <ranjith.vijayan@oracle.com>"


RUN echo "creating dir" && \
    mkdir -p /u01/ords && \
    mkdir -p /u01/config/scripts && \
    mkdir -p /u01/logs

COPY ["product/", "/u01/ords/"]
COPY ["scripts/", "/u01/config/scripts/"]

ENTRYPOINT ["/u01/config/scripts/run-ords.sh"]

EXPOSE 8888
