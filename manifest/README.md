## ENV INFO (default 값은 향후 변경 예정)
### paasta-portal info
| Name | Default Value |
|--|--|
| IF_USE_SWIFT_EXTERNAL_MARIADB | false |
| MARIADB_ADDRESS | "mariadb.paasta.svc.cluster.local" |
| MARIADB_PORT | 13306 |
| MARIADB_ADMIN_PASSWORD | admin |
| PORTAL_OPENSTACK_PROJECT_NAME | paasta-portal |
| PORTAL_OPENSTACK_PROJECT_DESC | portal binary_storage |
| PORTAL_OPENSTACK_USER_NAME | paasta-portal |
| PORTAL_OPENSTACK_USER_PASSWORD | paasta |
| PORTAL_OPENSTACK_REGION | paasta |
| PORTAL_OPENSTACK_USER_EMAIL | paasta@paasta.com |
| SWIFT_ADDRESS | localhost |
| KEYSTONE_PORT | 5000 |
| PROXY_PORT | 10008 |

### openstack info
| Name | Default Value |
|--|--|
| OS_USERNAME | admin |
| OS_PASSWORD | superuser |
| OS_PROJECT_NAME | admin |
| OS_USER_DOMAIN_NAME | Default |
| OS_PROJECT_DOMAIN_NAME | Default |
| OS_AUTH_URL | http://localhost:$KEYSTONE_PORT/v3 |
| OS_SWIFT_URL | http://localhost:$PROXY_PORT/v1 |
| OS_IDENTITY_API_VERSION | 3 |
| SWIFT_USER_PASSWORD | swift |
