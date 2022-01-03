# Openstack swift and keystone container image

This container makes it easy to run *integration tests* against OpenStack Keystone and OpenStack Swift object storage.
It is not suitable for production. 

The container starts both a swift and a keystone service so that integration
tests can run against a single container.

## Stack
This container is based on Ubuntu 20:04 and uses the
[Ubuntu Cloud Archive](https://wiki.ubuntu.com/OpenStack/CloudArchive) repository for
[OpenStack release Wallaby](https://docs.openstack.org/wallaby/install/).

## How to use this container
Build the image with

    docker buildx build -t keystone-swift .

Start the container using the following command:

    docker run -p 5000:5000 -p 8080:8080 --name keystone-swift keystone-swift

Stop it with

    docker stop keystone-swift

The following commands are available in the container:
- openstack
- keystone
- swift
- curl
- http (from https://httpie.org)
- jq (from https://stedolan.github.io/jq/)
- vim
- bash

## Preconfigured credentials
The container comes with 2 preconfigures accounts:
- admin / superuser
- swift / veryfast

### Keystone Identity v3 accounts 
Default endpoint http://127.0.0.1:5000/v3

#### Administrative account

    export OS_USERNAME=admin
    export OS_PASSWORD=superuser
    export OS_PROJECT_NAME=admin
    export OS_USER_DOMAIN_NAME=Default
    export OS_PROJECT_DOMAIN_NAME=Default
    export OS_AUTH_URL=http://127.0.0.1:5000/v3
    export OS_IDENTITY_API_VERSION=3

#### swift service account

    export OS_USERNAME=swift
    export OS_PASSWORD=veryfast
    export OS_PROJECT_NAME=service
    export OS_USER_DOMAIN_NAME=Default
    export OS_PROJECT_DOMAIN_NAME=Default
    export OS_AUTH_URL=http://127.0.0.1:5000/v3
    export OS_IDENTITY_API_VERSION=3

### Swift tempAuth accounts

Default endpoint http://127.0.0.1:8080/auth/v1.0

#### Admin account

    USERNAME=admin
    PASSWORD=admin
    TENANT_NAME=admin

#### tester account

    USERNAME=tester
    PASSWORD=testing
    TENANT_NAME=test


## Sample httpie commands

Keystone Identity v3

    echo '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"swift","domain":{"name":"Default"},"password":"veryfast"}}},"scope":{"project":{"domain":{"id":"default"},"name":"test"}}}}' | http POST :5000/v3/auth/tokens

TempAuth

    http http://127.0.0.1:8080/auth/v1.0 X-Storage-User:test:tester X-Storage-Pass:testing 

## Sample curl commands

Keystone Identity v3

    curl -X POST -H 'Content-Type: application/json' -d '{"auth":{"identity":{"methods":["password"],"password":{"user":{"name":"swift","domain":{"name":"Default"},"password":"veryfast"}}},"scope":{"project":{"domain":{"id":"default"},"name":"test"}}}}' http://127.0.0.1:5000/v3/auth/tokens

TempAuth

    curl -H 'X-Storage-User: test:tester' -H 'X-Storage-Pass: testing' http://127.0.0.1:8080/auth/v1.0

# License

`openstack-swift-keystone-docker` and all it sources are released under *Apache v2.0*.
