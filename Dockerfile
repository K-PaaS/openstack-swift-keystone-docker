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


ENV OS_USERNAME=admin
ENV OS_PASSWORD=superuser
ENV OS_PROJECT_NAME=admin
ENV OS_USER_DOMAIN_NAME=Default
ENV OS_PROJECT_DOMAIN_NAME=Default
ENV OS_AUTH_URL=http://localhost:5000/v3
ENV OS_SWIFT_URL=http://localhost:8080/v1
ENV OS_IDENTITY_API_VERSION=3

# Setup Keystone
RUN su -s /bin/sh -c "keystone-manage db_sync" keystone && \
    keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone && \
    keystone-manage credential_setup --keystone-user keystone --keystone-group keystone && \
    keystone-manage bootstrap --bootstrap-password ${OS_PASSWORD} \
        --bootstrap-admin-url ${OS_AUTH_URL} \
        --bootstrap-internal-url ${OS_AUTH_URL} \
        --bootstrap-public-url ${OS_AUTH_URL} \
        --bootstrap-region-id RegionOne && \
    sed 's/# Global configuration/# Global configuration\nServerName keystone/g' -i /etc/apache2/apache2.conf && \
    sed 's/Include ports.conf/# Include ports.conf/g' -i /etc/apache2/apache2.conf && \
    a2dissite 000-default.conf && \
    apachectl start && \
# Creating project and user
    openstack project create --domain default --description "Service Project" service && \
    openstack user create --domain default --password veryfast swift && \
    openstack role add --project service --user swift admin && \
# Connect swift to keystone
    openstack service create --name swift --description "OpenStack Object Storage" object-store && \
    openstack endpoint create --region RegionOne object-store internal $OS_SWIFT_URL/AUTH_%\(project_id\)s && \
    openstack endpoint create --region RegionOne object-store admin $OS_SWIFT_URL && \
    openstack endpoint create --region RegionOne object-store public $OS_SWIFT_URL/AUTH_%\(project_id\)s

# Setup Swift storage
RUN `#truncate -s 64MB /srv/swift-disk` && \
    `#mkfs.xfs /srv/swift-disk` && \
    `#echo '/srv/swift-disk /mnt/sdb1 xfs loop,noatime,nodiratime,nobarrier,logbufs=8 0 0'>>/etc/fstab ` && \
    mkdir /mnt/sdb1 && \
    `#mount /mnt/sdb1 &&` \
    mkdir /mnt/sdb1/1 && \
    chown swift:swift /mnt/sdb1/* && \
    ln -s /mnt/sdb1/1 /srv/1 && \
    mkdir -p /srv/1/node/sdb1 /srv/1/node/sdb5 /var/run/swift && \
    chown -R swift:swift /var/run/swift && \
    chown -R swift:swift /srv/1/

COPY etc/ /etc/
COPY swift/ /swift/

RUN apachectl start && \
    sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync && \
    chmod -R +x /swift/bin/ && \
    mkdir -p /swift/nodes && \
    mkdir -p /var/log/swift && \
    mkdir -p /var/run/swift && \
    sed -i 's/\$PrivDropToGroup syslog/\$PrivDropToGroup adm/' /etc/rsyslog.conf && \
    mkdir -p /var/log/swift/hourly && \
    chown -R syslog.adm /var/log/swift && \
    chmod -R g+w /var/log/swift && \
    echo swift:fingertips | chpasswd && \
    usermod -a -G sudo swift && \
    echo %sudo ALL=NOPASSWD: ALL >> /etc/sudoers && \
    ln -s /swift/nodes/1 /srv/1 && \
    chown -R swift:swift /swift/nodes /etc/swift && \
    sudo -u swift /swift/bin/remakerings && \
    mkdir -p /var/lib/swift && \
    chown swift:swift /var/lib/swift

EXPOSE 5000
EXPOSE 8080

CMD ["/swift/bin/launch.sh"]
