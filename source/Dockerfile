FROM oraclelinux:9

#install prequisites
RUN yum -y update && yum clean all
RUN yum install -y unixODBC unzip
RUN rm -f /etc/odbcinst.ini

#install fake systemctl
RUN echo -e '#!/bin/bash\necho "Systemctl called with $@"' > /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

#install qlik data movement gateway
RUN QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes pass=QlikDataMovement2025 yum -y install https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm
RUN yum clean all

# Set starting point of a new container
ENTRYPOINT tail -f /dev/null;

# Create installation mounting
RUN mkdir -p /opt/qlik/

#For main Linux version
#Oracle
ADD oracle*rpm /tmp/
RUN yum -y install /tmp/oracle-instantclient19.14-basic-19.14.0.0.0-1.x86_64.rpm
RUN yum -y install /tmp/oracle-instantclient19.14-sqlplus-19.14.0.0.0-1.x86_64.rpm
RUN yum -y install /tmp/oracle-instantclient19.14-odbc-19.14.0.0.0-1.x86_64.rpm
RUN rm -f oracle*.rpm
ENV PATH=/usr/lib/oracle/19.14/client64/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/lib/oracle/19.14/client64/lib:$LD_LIBRARY_PATH

#MS SQL Server
ADD ms*rpm /tmp/
RUN ACCEPT_EULA=Y yum -y install /tmp/msodbcsql18-18.2.2.1-1.x86_64.rpm
RUN ACCEPT_EULA=Y yum -y install /tmp/mssql-tools18-18.2.1.1-1.x86_64.rpm
ENV PATH=$PATH:/opt/mssql-tools/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/microsoft/msodbcsql/lib64

# MySQL
ADD mysql-*.rpm /tmp/
RUN yum install -y /tmp/mysql-community-common-8.0.25-1.el8.x86_64.rpm
RUN yum install -y /tmp/mysql-connector-odbc-8.0.25-1.el8.x86_64.rpm
RUN rm -f /tmp/mysql*.rpm
RUN echo "[MySQL]" >> /etc/odbcinst.ini
RUN echo "Description     = ODBC for MySQL" >> /etc/odbcinst.ini
RUN echo "Driver          = /usr/lib/libmyodbc8.so" >> /etc/odbcinst.ini
RUN echo "Setup           = /usr/lib/libodbcmyS.so" >> /etc/odbcinst.ini
RUN echo "Driver64        = /usr/lib64/libmyodbc8.so" >> /etc/odbcinst.ini
RUN echo "Setup64         = /usr/lib64/libodbcmyS.so" >> /etc/odbcinst.ini
RUN echo "FileUsage       = 1" >> /etc/odbcinst.ini

#Databricks
ADD simbaspark-2.6.22.1037-1.x86_64.rpm /tmp/
RUN yum install -y /tmp/simbaspark-2.6.22.1037-1.x86_64.rpm
RUN rm -f /tmp/simba*rpm

RUN echo '[Simba Spark ODBC Driver]' >> /etc/odbcinst.ini
RUN echo 'Description=Amazon Hive ODBC Driver (64-bit)' >> /etc/odbcinst.ini
RUN echo 'Driver=/opt/simba/spark/lib/64/libsparkodbc_sb64.so' >> /etc/odbcinst.ini

#Snowflake
ADD snowflake-odbc-2.25.12.x86_64.rpm /tmp/
RUN yum install -y /tmp/snowflake-odbc-2.25.12.x86_64.rpm
RUN rm -f /tmp/snowflake*rpm

