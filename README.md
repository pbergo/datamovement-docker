# Qlik Data Movement on Docker

## Summary

- [Qlik Data Movement on Docker](#qlik-data-movement-on-docker)
  - [Summary](#summary)
  - [License Summary](#license-summary)
  - [Disclaimer](#disclaimer)
  - [Introduction](#introduction)
  - [Docker image](#docker-image)
    - [Pulling Qlik Data Movement gateway docker image](#pulling-qlik-data-movement-gateway-docker-image)
    - [Build Qlik Data Movement Docker image](#build-qlik-data-movement-docker-image)
  - [Setup Container](#setup-container)
  - [Starting and stopping the Data Movement services](#starting-and-stopping-the-data-movement-services)
  - [Upgrading Qlik Data Movement](#upgrading-qlik-data-movement)
  - [Installing new ODBC drivers](#installing-new-odbc-drivers)

## License Summary

This project is made available under a modified MIT license. See the [LICENSE](LICENSE) file.

## Disclaimer

1. This is **not** a Qlik Supported Project/Product.
2. Contributions such as Issues, Pull Request and additional codes are welcomed.
3. **Qlik Inc.** or **Qlik Support** has no affiliation with this project. The initial version was developed by [Pedro Bergo](https://www.linkedin.com/in/pedro-bergo/) who is currently employed as Qlik Data Integration Senior Implementation Consultant at Qlik Data Professional Services Team.

## Introduction

This document was created to provide details how to use Qlik Data Movement Gateway on Docker environment. The information here doesn´t intend to cover all aspects of Docker environments, flavours and tools provided by market, like Swarm, Kubernetes or AWS-EKS.

The recommended approach for PS consultants during the project implementation is provide to customers basic information and artifacts (scripts and configuration files) to work with Docker, then it can be adapted to its own environments.

## Docker image

To accelerate the adoption of Qlik Data Movement in a containerized environement, you can use an existing docker image or you can build your own image. 

For both approaches you might to link the Qlik Data Movement gateway with your tenant before put any task to run.

### Pulling Qlik Data Movement gateway docker image
All the following commands must run using admin or sudo privilege.

```bash
# Open bash (bash or powerbash)
docker pull pedrobergo/qlikdatamovement:latest
```

This docker image contains:
a. Data Movement gateway installed version 2024.11.30
b. ODBC Drivers: Oracle, SQL Server, MySQL, Snowflake, Databricks and DB2 for iSeries
c. Guest OS: Red Hat Linux 9

Next step is [setup the container](#setup-container).

### Build Qlik Data Movement Docker image

If you want to build your own Docker image, please look the next information, remembering that you might to setup the tenant connection in a running container.

**Starting program start_qdmg.sh**

The following shell script is used to start gateway within a container, but also to generate the key and install ODBC drivers on it.

```bash
#!/bin/bash
# Expect four parameters:
#    1. Tenant URL
# Create data folder and grant user attunity ownership of it

if [ -z $1 ]; then
  echo "Usage: start_qdmg.sh <tenant_url>"
  exit 1
fi

# Install Qlik Data Movement
if [ ! -d "/opt/qlik" ]; then
    QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes rpm -ivh https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm
fi

# Set tenant_url and get registration key
if [ ! -f "/opt/qlik/gateway/movement/data/qdmg_regkey.txt" ]; then
        /opt/qlik/gateway/movement/bin/repagent agentctl qcs set_config --tenant_url "$1" >> /dev/null 2>&1
        /opt/qlik/gateway/movement/bin/repagent agentctl qcs get_registration > /opt/qlik/gateway/movement/data/qdmg_regkey.txt 2>&1
fi

# Install ODBC drivers
# comment installation lines you don´t need
if [ ! -d "/opt/qlik/gateway/movement/drivers/oracle" ]; then
        /opt/qlik/gateway/movement/drivers/bin/install oracle -a >> /dev/null 2>&1
fi
if [ ! -d "/opt/qlik/gateway/movement/drivers/postgres" ]; then
        /opt/qlik/gateway/movement/drivers/bin/install postgres -a >> /dev/null 2>&1
fi
if [ ! -d "/opt/qlik/gateway/movement/drivers/sqlserver" ]; then
        /opt/qlik/gateway/movement/drivers/bin/install sqlserver -a >> /dev/null 2>&1
fi
if [ ! -d "/opt/qlik/gateway/movement/drivers/mysql" ]; then
        /opt/qlik/gateway/movement/drivers/bin/install mysql -a >> /dev/null 2>&1
fi
if [ ! -d "/opt/qlik/gateway/movement/drivers/databricks" ]; then
        /opt/qlik/gateway/movement/drivers/bin/install databricks -a >> /dev/null 2>&1
fi
if [ ! -d "/opt/qlik/gateway/movement/drivers/snowflake" ]; then
        /opt/qlik/gateway/movement/drivers/bin/install snowflake -a >> /dev/null 2>&1
fi

# Run Qlik Data Movement Gateway
su qlik -c "/opt/qlik/gateway/movement/bin/agentctl service start" >> /dev/null 2>&1

```


**Dockerfile**

Create a file named 'Dockerfile' container the following lines.

```Dockerfile
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install required packages, mainly for installing drivers
RUN microdnf -y update
RUN microdnf install -y util-linux python3 dnf sudo tar yum procps

# Fake systemctl so the installer can run
RUN echo -e '#!/bin/bash\necho "Systemctl called with $@"' > /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

# Remove temp microdnf files
RUN microdnf clean all

# Set environment
ADD start_qdmg.sh /usr/bin/start_qdmg.sh
RUN chmod 775 /usr/bin/start_qdmg.sh
ENV QlikCloudTenant="pbergo-qtc.us.qlikcloud.com"

# Keep the container up
ENTRYPOINT /usr/bin/start_qdmg.sh ${QlikCloudTenant}; tail -f /dev/null
```

**Build the image from the Dockerfile. Needs to be run from the directory that contains the Dockerfile**
```bash
docker build -t qdmg_image ./
```

Next step is [setup the container](#setup-container).

## Setup Container

Prior to use Qlik Data Movement gateway, you must setup the container, linking it with your tenant.

**Steps to set up a Qlik Data Movement gateway in a container**

All the following commands must run using admin or sudo privilege.

```bash
# 1. Run Docker container.
# You might to define the tenant url to register it on Docker
docker run --name qdmg_container -d qdmg_image -e QlikCloudTenant="<tenant>.<region>.qlikcloud.com"

# 2. Get the registration keys and register it on the Data Movement gateway at QTC
docker container exec -it qdmg_container cat /opt/qlik/gateway/movement/data/qdmg_regkey.txt
```

## Starting and stopping the Data Movement services

Using the start_qdmg.sh script, every time you restart the container, it will check if there are any key generated, the start the service automatically.

```bash
# Restart the container
docker container restart qdmg_container
```

<a id="upgrade"></a>
## Upgrading Qlik Data Movement

To upgrade Qlik Data Movement, you can use the following steps

```bash
# Download and install new Qlik Data Movement gateway version
# You don´t need to provide the password if it didn´t set up during installation
docker container exec -it qdmg_container su -c "QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes yum -y upgrade https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm"

# Restart the container
docker container restart qdmg_container
```
## Installing new ODBC drivers

You can install you own ODBC drivers version, and Qlik provided a script to install everything for you

Tip: You still can perform installation using the old fashion way.

**MySQL**
    - Amazon Aurora MySQL
    - Amazon RDS for MySQL
    - Google Cloud SQL for MySQL
    - MariaDB
    - Microsoft Azure for MySQL
    - MySQL
    - Percona Server for MySQL

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install mysql

# 2. After installing, restart container
docker container restart qdmg_container
```

---


**PostgreSQL**
    - Amazon Aurora PostgreSQL
    - Amazon RDS for PostgreSQL
    - Microsoft Azure PostgreSQL
    - PostgreSQL

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install postgres

# 2. After installing, restart container
docker container restart qdmg_container
```

---

**Oracle**
    - Amazon RDS for Oracle
    - Oracle
    - Oracle Cloud

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install oracle

# 2. After installing, restart container
docker container restart qdmg_container
```

---

**Amazon Redshift**

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install sqlserver

# 2. After installing, restart container
docker container restart qdmg_container
```

---

**Databricks**

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install databricks

# 2. After installing, restart container
docker container restart qdmg_container
```

---

**Snowflake**

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install snowflake

# 2. After installing, restart container and service
docker container restart qdmg_container
```

---

**SQL Server (Log-based & CDC)**
- Microsoft SQL Server
- Azure Synapse Analytics
- Azure SQL Server

```bash
# 1. Perform the installation
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install sqlserver

# 2. After installing, restart container and service
docker container restart qdmg_container
```


- **Fabric**

```bash
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install fabric

# 2. After installing, restart container
docker container restart qdmg_container
```	

- **IBM DB2 for iSeries**

The next steps show how to install an IBM DB2 for iSeries ODBC driver.
```bash
# 1. Create db2i installation folder for IBM DB2 driver into container
docker container exec -it qdmg_container su qlik -c "mkdir -p /opt/qlik/gateway/movement/drivers/db2iseries"

# 2. Copy the IBM DB2 driver to container
docker cp ./ibm-iaccess-1.1.0.26-1.0.x86_64.rpm qdmg_container:/opt/qlik/gateway/movement/drivers/db2iseries

# 3. Install the driver within container
docker container exec -it qdmg_container /opt/qlik/gateway/movement/drivers/bin/install db2iseries

# 4. After installing, restart container
docker container restart qdmg_container
```


