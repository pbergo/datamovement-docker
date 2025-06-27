##############################################################################################################
# start_dmg.sh 
# A command line to install, update and start Qlik Data Movement services within a container
# It should be defined as ENTRYPOINT in Dockerfile
# Copyright (c) 2025 Qlik
# Environment Variables:
#  -Tenant URL = $QlikCloudTenant
#  -Update gateway = $QlikUpdateGateway
#  -Update odbc drivers = $QlikUpdateODBC
##############################################################################################################

function update_qdmg() {
        echo -e "Upgrading Qlik Data Movement gateway..."
        rpm -U https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm 2>&1
        if [ "$?" -ne 0 ]; then
                echo -e "Error upgrading Qlik Data Movement gateway !"
                return 1
        fi
        return 0
}

function update_odbc() {
        if [ "$updateodbc" = "all" ]; then
                #Update all
                update_driver oracle
                update_driver postgres
                update_driver sqlserver
                update_driver mysql
                update_driver databricks
                update_driver snowflake
        else
                #Update single driver
                update_driver "$updateodbc"
        fi
        return 0
}

# Set the parameters from env variables
tenanturl="$QlikCloudTenant"
updategateway="$QlikUpdateGateway"
updateodbc="$QlikUpdateODBC"

# Showing variables
echo "#############################################################################################################"
echo "start_dmg.sh - a command line to install, update and start Qlik Data Movement services within a container"
echo "Datetime $(date +'%Y-%m-%d %H:%M:%S')"
echo "Parameters:"
echo "  -Tenant URL = $tenanturl"
echo "  -Update gateway = $updategateway"
echo "  -Update odbc drivers = $updateodbc"
echo "#############################################################################################################"

# Check if QDMG is already installed
if [ ! -d "/opt/qlik" ]; then
        install_qdmg
else
        # If QDMG is already installed then check the parameters
        if [[ -n "$updategateway" && "$updategateway" == "yes" ]]; then
                update_qdmg
        fi
        if [[ -n "$updateodbc" && "$updateodbc" != "no" ]]; then
                echo "Updating drivers $updateodbc..."
                update_odbc
        fi
fi

# Run Qlik Data Movement Gateway
echo -e "\nStarting gateway service $(date +'%Y-%m-%d %H:%M:%S')..."
su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start" >> /dev/null 2>&1
ps -ef
echo -e "#############################################################################################################\n"
