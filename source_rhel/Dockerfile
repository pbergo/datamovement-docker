FROM registry.access.redhat.com/ubi9/ubi-minimal

# Install required packages, mainly for installing drivers
RUN microdnf -y update
RUN microdnf install -y util-linux python3 dnf sudo tar yum

# Fake systemctl so the installer can run
RUN echo -e '#!/bin/bash\necho "Systemctl called with $@"' > /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

# Download and install Data Movement Gateway
RUN QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes rpm -ivh https://github.com/qlik-download/saas-download-links/releases/download/qcs/qlik-data-gateway-data-movement.rpm

# Or copy from local folder and install
#COPY ./qlik-data-gateway-data-movement.rpm /tmp/qlik-data-gateway-data-movement.rpm
#WORKDIR /tmp/
#RUN QLIK_CUSTOMER_AGREEMENT_ACCEPT=yes rpm -ivh qlik-data-gateway-data-movement.rpm

# Remove temp microdnf files
RUN microdnf clean all

# Keep the container up
ENTRYPOINT ["/bin/sh", "-c", "tail -f /dev/null"]