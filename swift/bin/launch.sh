#!/bin/bash
# Setup Swift storage

mkdir -p /mnt/sdb1/1 ; \
chown swift:swift /mnt/sdb1/* ; \
ln -s /mnt/sdb1/1 /srv/1 ; \
mkdir -p /srv/1/node/sdb1 /srv/1/node/sdb5 /var/run/swift ; \
chown -R swift:swift /var/run/swift ; \
chown -R swift:swift /srv/1/

apachectl start ; \
sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync ; \
chmod -R +x /swift/bin/ ; \
mkdir -p /swift/nodes ; \
mkdir -p /var/log/swift ; \
mkdir -p /var/run/swift ; \
sed -i 's/\$PrivDropToGroup syslog/\$PrivDropToGroup adm/' /etc/rsyslog.conf ; \
mkdir -p /var/log/swift/hourly ; \
chown -R syslog.adm /var/log/swift ; \
chmod -R g+w /var/log/swift ; \
echo swift:fingertips | chpasswd ; \
usermod -a -G sudo swift ; \
echo %sudo ALL=NOPASSWD: ALL >> /etc/sudoers ; \
ln -s /swift/nodes/1 /srv/1 ; \
chown -R swift:swift /swift/nodes /etc/swift ; \
sudo -u swift /swift/bin/remakerings ; \
mkdir -p /var/lib/swift ; \
chown swift:swift /var/lib/swift ; \
apachectl stop ;

export OS_AUTH_URL=http://localhost:$KEYSTONE_PORT/v3
export OS_SWIFT_URL=http://localhost:$PROXY_PORT/v1

sed -i "s/5000/${KEYSTONE_PORT}/" /etc/apache2/sites-available/keystone.conf


if [ "$IF_USE_SWIFT_EXTERNAL_MARIADB" == "true" ]; then echo mysql-server mysql-server/root_password password $MARIADB_ADMIN_PASSWORD | debconf-set-selections && \
   echo mysql-server mysql-server/root_password_again password $MARIADB_ADMIN_PASSWORD | debconf-set-selections && \
   sed -e "s/connection = sqlite:\/\/\/\/var\/lib\/keystone\/keystone.db/connection = mysql+pymysql:\/\/keystone:swiftstack@$MARIADB_ADDRESS:$MARIADB_PORT\/keystone/" -i /etc/keystone/keystone.conf

    su -s /bin/sh -c "keystone-manage db_sync" keystone && \
    keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone && \
    keystone-manage credential_setup --keystone-user keystone --keystone-group keystone && \
    keystone-manage bootstrap --bootstrap-password ${OS_PASSWORD} \
        --bootstrap-admin-url ${OS_AUTH_URL} \
        --bootstrap-internal-url ${OS_AUTH_URL} \
        --bootstrap-public-url ${OS_AUTH_URL} \
        --bootstrap-region-id RegionOne && \
    apachectl start && \
    # Creating project and user
    if (( $( openstack project list | grep " service " -c ) >= "1" )); then echo "already exists project service"; else openstack project create --domain default --description "Service Project" service ; fi ; \
    if (( $( openstack user list | grep " swift " -c ) >= "1" )); then openstack user delete swift ; fi ; \
    openstack user create --domain default --password $SWIFT_USER_PASSWORD swift ; \
    openstack role add --project service --user swift admin && \
    # Connect swift to keystone
    if (( $( openstack service list | grep " swift " -c ) >= "1" )); then echo "already exists service swift"; else openstack service create --name swift --description "OpenStack Object Storage" object-store ; fi ; \
    if (( $( openstack endpoint list --region RegionOne --service swift --interface admin --print-empty -f value | wc -l  ) >= "1" )); then openstack endpoint set --url $OS_SWIFT_URL $(openstack endpoint list --region RegionOne --service object-store --interface admin --print-empty -f value | cut -d " " -f 1)  ; else openstack endpoint create --region RegionOne object-store admin $OS_SWIFT_URL ; fi ; \
if (( $( openstack endpoint list --region RegionOne --service swift --interface internal --print-empty -f value | wc -l  ) >= "1" )); then openstack endpoint set --url $OS_SWIFT_URL/AUTH_%\(project_id\)s $(openstack endpoint list --region RegionOne --service object-store --interface internal --print-empty -f value | cut -d " " -f 1)  ; else openstack endpoint create --region RegionOne object-store internal $OS_SWIFT_URL/AUTH_%\(project_id\)s ; fi ; \
if (( $( openstack endpoint list --region RegionOne --service swift --interface public --print-empty -f value | wc -l  ) >= "1" )); then openstack endpoint set --url http://$SWIFT_ADDRESS:$PROXY_PORT/v1/AUTH_%\(project_id\)s $(openstack endpoint list --region RegionOne --service object-store --interface public --print-empty -f value | cut -d " " -f 1)  ; else openstack endpoint create --region RegionOne object-store public http://$SWIFT_ADDRESS:$PROXY_PORT/v1/AUTH_%\(project_id\)s ; fi ; \
    apachectl stop ; fi

sleep 5;


# openstack portal setting

apachectl start && \
if (( $( openstack project list | grep " $PORTAL_OPENSTACK_PROJECT_NAME " -c ) >= "1" )); then echo "already exists service $PORTAL_OPENSTACK_PROJECT_NAME"; else openstack project create $PORTAL_OPENSTACK_PROJECT_NAME ; fi ; \
if (( $( openstack user list | grep " $PORTAL_OPENSTACK_USER_NAME " -c ) >= "1" )); then echo "already exists user $PORTAL_OPENSTACK_USER_NAME"; else openstack user create --password $PORTAL_OPENSTACK_USER_PASSWORD --project $PORTAL_OPENSTACK_PROJECT_NAME $PORTAL_OPENSTACK_USER_NAME ; fi ; \
openstack role add --project $PORTAL_OPENSTACK_PROJECT_NAME --user $PORTAL_OPENSTACK_USER_NAME admin ; \
if (( $( openstack endpoint list --region $PORTAL_OPENSTACK_REGION --service swift --interface admin --print-empty -f value | wc -l  ) >= "1" )); then openstack endpoint set --url $OS_SWIFT_URL $(openstack endpoint list --region $PORTAL_OPENSTACK_REGION --service object-store --interface admin --print-empty -f value | cut -d " " -f 1)  ; else openstack endpoint create --region $PORTAL_OPENSTACK_REGION swift admin $OS_SWIFT_URL ; fi ; \
if (( $( openstack endpoint list --region $PORTAL_OPENSTACK_REGION --service swift --interface internal --print-empty -f value | wc -l  ) >= "1" )); then openstack endpoint set --url http://localhost:$PROXY_PORT/v1/AUTH_%\(project_id\)s $(openstack endpoint list --region $PORTAL_OPENSTACK_REGION --service object-store --interface internal --print-empty -f value | cut -d " " -f 1)  ; else openstack endpoint create --region $PORTAL_OPENSTACK_REGION swift internal http://localhost:$PROXY_PORT/v1/AUTH_%\(project_id\)s ; fi ; \
if (( $( openstack endpoint list --region $PORTAL_OPENSTACK_REGION --service swift --interface public --print-empty -f value | wc -l  ) >= "1" )); then openstack endpoint set --url http://$SWIFT_ADDRESS:$PROXY_PORT/v1/AUTH_%\(project_id\)s $(openstack endpoint list --region $PORTAL_OPENSTACK_REGION --service object-store --interface public --print-empty -f value | cut -d " " -f 1)  ; else openstack endpoint create --region $PORTAL_OPENSTACK_REGION swift public http://$SWIFT_ADDRESS:$PROXY_PORT/v1/AUTH_%\(project_id\)s ; fi ; \
apachectl stop


sed -e "s/bind_port = 8080/bind_port = ${PROXY_PORT}/" -i /etc/swift/proxy-server.conf
sed -e "s/password = veryfast/password = ${SWIFT_USER_PASSWORD}/" -i /etc/swift/proxy-server.conf
sed -e "s/localhost:5000/localhost:${KEYSTONE_PORT}/" -i /etc/swift/proxy-server.conf


echo "service start"
service rsyslog start
service rsync start
service memcached start
service swift-proxy start
service swift-container start
service swift-account start
service swift-object start
apachectl -DFOREGROUND
