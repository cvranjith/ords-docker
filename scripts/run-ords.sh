#!/bin/bash
function set_defaults(){
    export ORDS_HOME=/u01/ords
    export ORDS_CONFIG=/u01/config/ords
    export DB_POOL=${DB_POOL:-"default"}
    export DB_PORT=${DB_PORT:-"1521"}
    export SYSDBA_USER=${SYSDBA_USER:-"SYS"}

    export PROXY_USER_TABLESPACE=${PROXY_USER_TABLESPACE:-"SYSAUX"}
    export PROXY_USER_TEMP_TABLESPACE=${PROXY_USER_TEMP_TABLESPACE:-"TEMP"}
    export SCHEMA_TABLESPACE=${PROXY_USER_TABLESPACE:-"SYSAUX"}
    export SCHEMA_TEMP_TABLESPACE=${PROXY_USER_TEMP_TABLESPACE:-"TEMP"}

    export HTTP_PORT=${HTTP_PORT:-"8888"}
    export STANDALONE_USE_HTTPS=${STANDALONE_USE_HTTPS:-"false"}
    export FEATURE_SDW=${FEATURE_SDW:-"true"}
    export FEATURE_REST_ENABLED_SQL=${FEATURE_REST_ENABLED_SQL:-"true"}
    export FEATURE_DB_API=${FEATURE_DB_API:-"true"}
    
    export JDBC_INACTIVITY_TIMEOUT=${JDBC_INACTIVITY_TIMEOUT:-"1800"}
    export JDBC_INITIAL_LIMIT=${JDBC_INITIAL_LIMIT:-"10"}
    export JDBC_MAX_CONNECTION_REUSE_COUNT=${JDBC_MAX_CONNECTION_REUSE_COUNT:-"1000"}
    export JDBC_MAX_LIMIT=${JDBC_MAX_LIMIT:-"20"}
    export JDBC_MAX_STATEMENTS_LIMIT=${JDBC_MAX_STATEMENTS_LIMIT:-"10"}
    export JDBC_MIN_LIMIT=${JDBC_MIN_LIMIT:-"1"}
    export JDBC_STATEMENT_TIMEOUT=${JDBC_STATEMENT_TIMEOUT:-"900"}
    
    export _JAVA_OPTIONS=${_JAVA_OPTIONS:-"-Xms1500M -Xmx1500M"}
    export _JAVA_OPTIONS_CONFIG=${_JAVA_OPTIONS_CONFIG:-"-Xms128M -Xmx128M"}

    export FILE_LOG_REQUIRED=${FILE_LOG_REQUIRED:-"true"}
    export FILE_LOG_PATH=${FILE_LOG_PATH:-"/u01/logs"}
    export LOG_HANDLERS=${LOG_HANDLERS:-"java.util.logging.FileHandler, java.util.logging.ConsoleHandler"}
    export LOGGING_LEVEL=${LOGGING_LEVEL:-"INFO"}
    export FILE_HANDLER_PATTERN=${FILE_HANDLER_PATTERN:-"$FILE_LOG_PATH/ords-log-%g.log"}
    export FILE_HANDLER_LIMIT=${FILE_HANDLER_LIMIT:-"500000"}
    export FILE_HANDLER_COUNT=${FILE_HANDLER_COUNT:-"5"}
    export FILE_HANDLER_FORMATTER=${FILE_HANDLER_FORMATTER:-"java.util.logging.SimpleFormatter"}
    export FILE_HANDLER_LEVEL=${FILE_HANDLER_LEVEL:-"INFO"}
    export CONSLE_HANDLER_FORMATTER=${CONSLE_HANDLER_FORMATTER:-"java.util.logging.SimpleFormatter"}
    export CONSOLE_HANDLER_LEVEL=${CONSOLE_HANDLER_LEVEL:-"INFO"}
    export LOGGING_PROPERTIES_FILE="${ORDS_HOME}/logging.properties"
}

function set_prop() {
    echo "setting Prop " $1
    echo "${ORDS_HOME}/bin/ords --config ${ORDS_CONFIG} config set $1"
    ${ORDS_HOME}/bin/ords --config ${ORDS_CONFIG} config set $1
}
function set_jdbc_props(){
    echo "Going to set JDBC props"
    set_prop "jdbc.InactivityTimeout ${JDBC_INACTIVITY_TIMEOUT}"
    set_prop "jdbc.InitialLimit ${JDBC_INITIAL_LIMIT}"
    set_prop "jdbc.MaxConnectionReuseCount ${JDBC_MAX_CONNECTION_REUSE_COUNT}"
    set_prop "jdbc.MaxLimit ${JDBC_MAX_LIMIT}"
    set_prop "jdbc.MaxStatementsLimit ${JDBC_MAX_STATEMENTS_LIMIT}"
    set_prop "jdbc.MinLimit ${JDBC_MIN_LIMIT}"
    set_prop "jdbc.statementTimeout ${JDBC_STATEMENT_TIMEOUT}"
}
function set_other_props(){
    echo "Going to set Other props"
    if [[ "$FILE_LOG_REQUIRED" == "true" ]]
    then
        set_prop "standalone.access.log ${FILE_LOG_PATH}"
    fi
    for i in {1..100}
    do
        l_name="CONFIG_SET_$i"
        l_val=${!l_name}
        echo "$i : ${l_name} : ${l_val}" 
        if [[ "${l_val}" == "" ]]
        then
            echo "CONFIG_SET_$i is not set"
            break
        fi
        set_prop "$l_val"
    done
}
function set_logger(){
    if [[ "$FILE_LOG_REQUIRED" == "true" ]]
    then
        echo "File Logging will be done to $FILE_LOG_PATH"
        echo "handlers= ${LOG_HANDLERS}
.level= ${LOGGING_LEVEL}
java.util.logging.FileHandler.pattern = ${FILE_HANDLER_PATTERN}
java.util.logging.FileHandler.limit = ${FILE_HANDLER_LIMIT}
java.util.logging.FileHandler.count = ${FILE_HANDLER_COUNT}
java.util.logging.FileHandler.formatter = ${FILE_HANDLER_FORMATTER}
java.util.logging.FileHandler.level = ${FILE_HANDLER_LEVEL}
java.util.logging.ConsoleHandler.level = ${CONSOLE_HANDLER_LEVEL}
java.util.logging.ConsoleHandler.formatter = ${CONSLE_HANDLER_FORMATTER} " > ${LOGGING_PROPERTIES_FILE}
        export _JAVA_OPTIONS="${_JAVA_OPTIONS} -Djava.util.logging.config.file=${LOGGING_PROPERTIES_FILE}"
    fi
}
function install_simple() {
    echo "Going to do simple install"
    ${ORDS_HOME}/bin/ords --config ${ORDS_CONFIG} install \
     --db-only \
     --admin-user ${SYSDBA_USER} \
     --db-hostname ${DB_HOSTNAME} \
     --db-port ${DB_PORT} \
     --db-servicename ${DB_SERVICENAME} \
     --proxy-user-tablespace ${PROXY_USER_TABLESPACE} \
     --proxy-user-temp-tablespace ${PROXY_USER_TEMP_TABLESPACE} \
     --schema-tablespace ${SCHEMA_TABLESPACE} \
     --schema-temp-tablespace ${SCHEMA_TEMP_TABLESPACE} \
     --proxy-user \
     --password-stdin <<EOF
${SYSDBA_PASSWORD}
${ORDS_PUBLIC_USER_PASSWORD}
EOF
    echo "Simple install Done!"
}

function serve_ords() {
    echo "Going to do Configure"
    if [[ "${STANDALONE_USE_HTTPS}" == "true" ]]
    then
        l_secure=" --secure "
    fi
    if [[ "${DB_POOL}" == "default" ]]
    then
        echo "Default Pool"
    else
        echo "DB Pool ${DB_POOL}"
        l_db_pool=" --db-pool ${DB_POOL} "
    fi
    l_jo="$_JAVA_OPTIONS"
    export _JAVA_OPTIONS=${_JAVA_OPTIONS_CONFIG}
    ${ORDS_HOME}/bin/ords --config ${ORDS_CONFIG} install \
     --config-only \
     --db-hostname ${DB_HOSTNAME} \
     --db-port ${DB_PORT} \
     --db-servicename ${DB_SERVICENAME} \
     --feature-db-api ${FEATURE_DB_API} \
     --feature-rest-enabled-sql ${FEATURE_REST_ENABLED_SQL} \
     --feature-sdw ${FEATURE_SDW} \
     ${l_db_pool} \
     --proxy-user \
     --password-stdin <<EOF
${ORDS_PUBLIC_USER_PASSWORD}
EOF
    set_jdbc_props
    set_other_props
    export _JAVA_OPTIONS=${l_jo}
    set_logger
    echo "Going to serve"
    ${ORDS_HOME}/bin/ords serve ${l_secure} --port ${HTTP_PORT}
}

##main script starts here
echo "Starting ORDS"
set_defaults
if [[ "${ORDS_ARGS}" == "install-simple" ]]
then
   install_simple
else
   serve_ords
fi
