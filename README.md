


### How to Build

* Download latest ords installer from  Use this link for the latest version update or specific version https://www.oracle.com/database/technologies/appdev/rest-data-services-downloads.html.
* unzip into /product folder
* Run docker build and push it. Example below

``` bash
export http_proxy='http://www-proxy.us.oracle.com:80'
export https_proxy='http://www-proxy.us.oracle.com:80'
export no_proxy="localhost,.oraclecorp.com,us.oracle.com,.oraclecloud.com,.in.oracle.com,nl.oracle.com,svc.cluster.local,127.0.0.1,.oraclevcn.com"
 
cd product
wget https://download.oracle.com/otn_software/java/ords/ords-latest.zip
unzip ords-latest.zip
rm -f rm -f ords-latest.zip
cd ..
docker build -t fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle/ords/oracle-ords:22.1.1 .
docker push fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle/ords/oracle-ords:22.1.1 .
```




### USAGE

As ORDS 22.1 onwards the installer has undergone major changes, a separate Dockerfile is maintained. Majority of the docker arguments are kept same as before, however some minor changes are there.


Following simplified methods can be followed to install ORDS and RESTUTIL

* Pre-Requisites
* Install ORDS
* Run ORDS container
* Install RESTUTIL
* UnInstall ORDS


### Pre requisite:  Running Oracle DB

Pre-Requisites

These steps in this page are documented using 19c. however the steps are exactly same for other databases - 12c/11g/20c. Just change the variables accordingly

```
docker run -dit --net my-net --name ords-db -p 2521:1521 fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle-db/oracle-oracle-19.3:embedded
```

Tip: For testing purpose: To quickly spin a blank 19c DB you may follow this 2.6.3 Running Oracle DB 19c (19.3-ee) all-inclusive  or a more lighter 12c DB using  2.6.1 Running an all-inclusive small-footprint Oracle DB (12c) on Docker 


### Install ORDS

This step will install ORDS (or update) in your database. SYS or an appropriate DBA user account is required to do this. This is a temporary container, and after installation the container will terminate.

```
docker run -it --rm \
  --net my-net \
  -e DB_HOSTNAME=ords-db \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=PDB1 \
  -e SYSDBA_PASSWORD=Oracle123 \
  -e ORDS_ARGS="install-simple" \
  -e ORDS_PUBLIC_USER_PASSWORD=OrdsPU123 \
fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle/ords/oracle-ords:22.3
```

PS: In case you dont want to use SYS user for installing ORDS, a privileged user can be used. For this


Starting with ORDS 19.2 release, the Oracle REST Data Services installation archive file contains a script, ords_installer_privileges.sql which is located in the installer folder. The script provides the assigned database user the privileges to install, upgrade, validate and uninstall ORDS in Oracle Pluggable Database or Oracle 11g.

Perform the following steps:

    Using SQLcl or SQL*Plus, connect to Oracle PDB or 11g database with SYSDBA privileges.

Execute the following script providing the database user:
```
SQL> create user ORDS_INST identified by SuperSecret007;

SQL> @/path/to/installer/ords_installer_privileges.sql ORDS_INST
SQL> exit
```

You can then pass the user id (instead of default SYS) as below while running container.
```
-e SYSDBA_USER=ORDS_INST \
-e SYSDBA_PASSWORD=SuperSecret007 \
```

You may lock/drop the ORDS_INST account after installation

Run ORDS container


After the install is done using the temporary container, we can run a permanent container using the same image.

Below can be used to create container that exposes non-ssl (i.e. HTTP) endpoints and also enable SQL Developer Web (suitable for development envs)
```
docker run -dit --name ords-c-221 \
  --net my-net \
  -p 32517:8888 \
  -e DB_HOSTNAME=ords-db \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=PDB1 \
  -e ORDS_PUBLIC_USER_PASSWORD=OrdsPU123 \
fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle/ords/oracle-ords:22.3
```

Or With the below Minimal arguments we can create SSL (HTTPS) endpoints.

```
docker run -dit --name ords-c-221 \
  --net my-net \
  -p 32515:8888 \
  -e DB_HOSTNAME=ords-db \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=PDB1 \
  -e ORDS_PUBLIC_USER_PASSWORD=OrdsPU123 \
  -e STANDALONE_USE_HTTPS="true" \
fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle/ords/oracle-ords:22.3
```

Note:

ORDS Supports additional configuration properties as described in https://docs.oracle.com/en/database/oracle/oracle-rest-data-services/22.1/ordig/about-REST-configuration-files.html#GUID-FE96042C-AD0E-4008-B02C-5C1360C94505

To set specific values, you can pass env vars starting with name CONFIG_SET_1 , CONFIG_SET_2 and so on with the exact property name followed by values, separate by a space. The docker script will call ORDS set config commands to set these properties in the config files

E.g.
```
docker run -dit --name ords-c-221 \
    --net my-net \
    -p 32517:8888 \
    -e DB_HOSTNAME=ords-db \
    -e DB_PORT=1521 \
    -e DB_SERVICENAME=PDB1 \
    -e ORDS_PUBLIC_USER_PASSWORD=OrdsPU123 \
    -e _JAVA_OPTIONS="-Xms1500M -Xmx1500M" \
    -e CONFIG_SET_1="jdbc.MaxLimit 50" \
    -e CONFIG_SET_2="cache.metadata.enabled true" \
    -e CONFIG_SET_3="cache.metadata.timeout 180s" \
fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle/ords/oracle-ords:22.3
```


Note: Following additional optional JDBC parameters can be passed as env vars to set the JDBC Pool parameters. (This is carried forward from the legacy docker file)
 Expand source

Sample compose file:


Install RESTUTIL

Rest Util is a simple wrapper written to leverage ORDS features. to install , just run the below command.... A schema along with a few objects will be created. the value. sys or appropriate DBA account needs to be passed to run this. Defaullt schema name is RESTUTIL. it can be changed as required. last 3 arguments are SCHEMANAME PASSWORD Default-tablespace.


Alternatively / if you dont have access to the install scripts' http endpoint, you can copy the restuil install folder into the container and execute locally
docker cp /scratch/share/japac-file-share-mnt/scripts/ords/restutil-v3 ords-db:/tmp/
docker exec -it ords-db bash -c "sqlplus sys/Oracle123@PDB1 as sysdba @/tmp/restutil-v3/install-rest-util.sql RESTUTIL RESTUTIL USERS"


UInstall ORDS

Use the ORDS_ARGS "uninstall --interactive" and follow the instructions.

```
docker run -it --rm \
  --net my-net \
  -e DB_HOSTNAME=ords-db \
  -e DB_PORT=1521 \
  -e DB_SERVICENAME=PDB1 \
  -e ORDS_PUBLIC_USER_PASSWORD=OrdsPU123 \
  -e ORDS_ARGS=" uninstall --interactive" \
fsgbu-mum-128.snbomprshared1.gbucdsint02bom.oraclevcn.com:5000/oracle/ords/oracle-ords:22.3

```

