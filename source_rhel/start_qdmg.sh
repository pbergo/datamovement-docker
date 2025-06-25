#!/bin/bash
# Expect four parameters:
#    1. Tenant URL
# Create data folder and grant user attunity ownership of it

if [ -z $1 ]; then
  echo "Usage: start_qdmg.sh <tenant_url>"
  exit 1
fi

if [ ! -f "/opt/qlik/gateway/movement/data/qdmg_regkey.txt" ]; then
        # Setup the tenant url
        /opt/qlik/gateway/movement/bin/repagent agentctl qcs set_config --tenant_url "$1" >> /dev/null 2>&1

        #Generate the tenant key
        /opt/qlik/gateway/movement/bin/repagent agentctl qcs get_registration > /opt/qlik/gateway/movement/data/qdmg_regkey.txt 2>&1

        #Install ODBC drivers -- You can install any driver you want
        /opt/qlik/gateway/movement/drivers/bin/install oracle -a >> /dev/null 2>&1
        /opt/qlik/gateway/movement/drivers/bin/install postgres -a >> /dev/null 2>&1
        /opt/qlik/gateway/movement/drivers/bin/install sqlserver -a >> /dev/null 2>&1
        /opt/qlik/gateway/movement/drivers/bin/install mysql -a >> /dev/null 2>&1
        /opt/qlik/gateway/movement/drivers/bin/install databricks -a >> /dev/null 2>&1
        /opt/qlik/gateway/movement/drivers/bin/install snowflake -a >> /dev/null 2>&1
fi
# Run Qlik Data Movement Gateway
su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start" >> /dev/null 2>&1