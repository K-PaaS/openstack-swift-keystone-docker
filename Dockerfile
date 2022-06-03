FROM ubuntu:20.04
  
ENV DEBIAN_FRONTEND=noninteractive

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-get update -q \
    && apt-get --no-install-recommends install -yq \
        software-properties-common \
    && add-apt-repository -y cloud-archive:wallaby \
    && apt-get update -q \
    && apt-get upgrade -yq -o Dpkg::Options::="--force-confold" \
    && apt-get --no-install-recommends install -yq \
        openstack-release \
        keystone \
        swift \
        swift-proxy \
        swift-account \
        swift-container \
        swift-object \
        memcached \
        xfsprogs \
        rsync \
        rsyslog \
        sudo \
        python3-keystonemiddleware \
        python3-openstackclient \
        python3-keystoneclient \
# Conveniences
        python3-swiftclient \
        curl \
        httpie \
        jq \
        vim-tiny

# paasta-portal info
ENV IF_USE_SWIFT_EXTERNAL_MARIADB       false
ENV MARIADB_ADDRESS                     "mariadb.paasta.svc.cluster.local"
ENV MARIADB_PORT                        13306
ENV MARIADB_ADMIN_PASSWORD              admin
ENV PORTAL_OPENSTACK_PROJECT_NAME       paasta-portal
ENV PORTAL_OPENSTACK_PROJECT_DESC       "portal binary_storage"
ENV PORTAL_OPENSTACK_USER_NAME          paasta-portal
ENV PORTAL_OPENSTACK_USER_PASSWORD      paasta
ENV PORTAL_OPENSTACK_REGION             paasta
ENV PORTAL_OPENSTACK_USER_EMAIL         paasta@paasta.com
ENV SWIFT_ADDRESS                       localhost
ENV KEYSTONE_PORT                       5000
ENV PROXY_PORT                          10008


# Openstack info
ENV OS_USERNAME=admin
ENV OS_PASSWORD=superuser
ENV OS_PROJECT_NAME=admin
ENV OS_USER_DOMAIN_NAME=Default
ENV OS_PROJECT_DOMAIN_NAME=Default
ENV OS_AUTH_URL=http://localhost:$KEYSTONE_PORT/v3
ENV OS_SWIFT_URL=http://localhost:$PROXY_PORT/v1
ENV OS_IDENTITY_API_VERSION=3
ENV SWIFT_USER_PASSWORD=swift


RUN sed 's/# Global configuration/# Global configuration\nServerName keystone/g' -i /etc/apache2/apache2.conf && \
    sed 's/Include ports.conf/# Include ports.conf/g' -i /etc/apache2/apache2.conf && \
    a2dissite 000-default.conf ;


# Setup Swift storage

COPY etc/ /etc/
COPY swift/ /swift/

RUN chmod -R +x /swift/bin/



CMD ["/swift/bin/launch.sh"]
