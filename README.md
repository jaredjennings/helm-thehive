# Unofficial Helm chart for TheHive

This repository contains a Helm chart that can install
[TheHive](https://thehive-project.org) 4, "security incident response
for the masses," onto a Kubernetes cluster.

## Trying it out

It's early days, but if you want to try it out, clone this repository,
cd into it, and

```
helm install my-thehive .
```

You'll need to customize the values.yaml or provide some `--set`
command line options, of course.


### Smallest install: local database, index and attachments

On my single-node home k3s 1.20.2 cluster with stock Traefik 1.7 and
Helm 3.5.2, this does the trick for me:

```
helm install -n thehive my-thehive . \
             --set storageClass=local-path \
             --set 'ingress.hosts[0].host=hive.k.my.dns.domain' \
             --set 'ingress.hosts[0].paths[0].path=/'
```

Defaults are for local index storage, local database storage, and
attachment storage, all on Kubernetes persistent volumes with the
default access modes (`ReadWriteOnce`). The `storageClass` you need to
use will vary with your Kubernetes distribution and its configuration.

Now, this kind of install is not the best use of this Helm
chart. Clearly you cannot scale past a single replica of TheHive
because of the local storage; but the chart sets up a Kubernetes
Deployment for TheHive, which expects in the face of any change to
stand up the new TheHive Pod before taking down the old one. But the
new one fails to become ready because the old one has files locked. To
work around this, before changing anything (`helm upgrade` for
example) or deleting a Pod, you must stand down the one you have:

```
kubectl scale --replicas=0 deployment my-thehive
```

### Cassandra for data

Write a `values-as-given.yaml`:

```
storageClass: local-path
ingress:
  hosts:
    - host: hive.k.my.dns.domain
      paths:
       - path: /
cassandra:
  enabled: true
  persistence:
    storageClass: local-path
  dbUser:
    password: "my_super_secure_password"
elasticsearch:
  eck:
    enabled: true
    name: thc
```

Now

```
helm install -n mynamespace hivename . -f values-as-given.yaml
```

#### Idempotence

You should specify a value for `cassandra.dbUser.password`. Otherwise
a new Secret will be generated every time you `helm upgrade`; but the
actual value of the password will not change, because the persistent
volume containing the password also contains the data, and it is not
deleted and recreated. When you specify a password, a new one is not
randomly generated. You should indeed rotate Cassandra passwords, but
it appears the Bitnami Cassandra chart may not handle this for you.

## Caveats

Upon first installation, TheHive may fail to connect to Cassandra for
a few minutes. Try waiting it out.

## TheHive 3

To deploy TheHive 3, supply `image.repository` value
`thehiveproject/thehive` and `image.tag` `3.5.1`. Configuration will
be altered accordingly. At [this point in
history](https://blog.thehive-project.org/2021/03/19/thehive-reloaded-4-1-0-is-out/),
i.e. after March 19, 2021, no one should take TheHive 3 to production.

## Improving it

If this chart doesn't flex in a way you need it to, and there isn't
already an issue about it, please file one.

If you can see your way to making an improvement, shoot a pull request
over.


## The future

I hope that one day this chart and its peers will be part of the
solution to https://github.com/TheHive-Project/TheHive/issues/1224. 

# Parameters

This is a non-exhaustive list of Hive-specific parameters.

TheHive can store its main data in a Cassandra database or, for small
single-node deployments, a locally stored BerkeleyJE database. See
below for Cassandra and localDatabaseStorage settings; if Cassandra is
enabled, local database storage settings are ignored.

TheHive can store its index data in an Elasticsearch index or, for
small single-node deployments, a locally stored Lucene index. See
below for Elasticsearch and localIndexStorage settings; if
Elasticsearch is enabled, local index storage settings are ignored.

TheHive can store case attachment files in an HDFS or on local
persistent storage. At this writing, this chart does not support
HDFS. See below for attachmentStorage settings.


## Local Storage

There are three purposes for which TheHive might need local persistent
storage: for storing attachments, for local database storage, and for
local index storage. As a convenience, you can specify the
storageClass to use for all three with one setting; you can also
specify the storageClass for each independently as needed.

| Parameter                             | Description                                                        | Default               |
| --                                    | --                                                                 | --                    |
| storageClass                          | Storage class to use for local storage if not otherwise specified. | "default"             |
| attachmentStorage.pvc.enabled         | Set this to true to store attachments locally on a PVC.            | true                  |
| attachmentStorage.pvc.storageClass    | Storage class to use for attachment storage.                       | value of storageClass |
| attachmentStorage.pvc.size            | Size of persistent volume claim (PVC) for attachments.             | "10Gi"                |
| localDatabaseStorage.pvc.enabled      | Set this to true to store main data locally on a PVC.              | true                  |
| localDatabaseStorage.pvc.storageClass | Storage class to use for local database storage.                   | value of storageClass |
| localDatabaseStorage.pvc.size         | Size of persistent volume claim (PVC) for local database.          | "10Gi"                |
| localIndexStorage.pvc.enabled         | Set this to true to store index data locally on a PVC.             | true                  |
| localIndexStorage.pvc.storageClass    | Storage class to use for local index storage.                      | value of storageClass |
| localIndexStorage.pvc.size            | Size of persistent volume claim (PVC) for local index.             | "10Gi"                |


## Elasticsearch

| Parameter                      | Description                                                          | Default             |
| ---------                      | -----------                                                          | -------             |
| elasticsearch.eck.enabled      | Set this to true if you used ECK to set up an Elasticsearch cluster. | false               |
| elasticsearch.eck.name         | Set to the name of the `Elasticsearch` custom resource.              | nil                 |
| elasticsearch.external.enabled | Set this to true if you have a non-ECK Elasticsearch server/cluster. | false               |
| elasticsearch.username         | Username with which to authenticate to Elasticsearch.                | elastic<sup>1,2</sup> |
| elasticsearch.userSecret       | Secret containing the password for the named user.                   | nil<sup>1</sup>     |
| elasticsearch.url              | URL to Elasticsearch server/cluster.                                 | nil<sup>1</sup>     |
| elasticsearch.tls              | Set this to true to provide a CA cert to trust.                      | true<sup>1</sup>    |
| elasticsearch.caCertSecret     | Secret containing the CA certificate to trust.                       | nil<sup>1,3</sup>     |
| elasticsearch.caCert           | PEM text of the CA cert to trust.                                    | nil<sup>1,3</sup>   |

Notes:

1. If you use ECK to set up an Elasticsearch cluster, you don't need to specify this.
2. The user secret should be an opaque secret, with data whose key is the username and value is the password.
3. The CA cert secret should be an opaque secret with data whose key
   is 'tls.crt' and value is the PEM-encoded certificate. If you don't
   have such a secret already, provide the PEM-encoded certificate as
   the value of `elasticsearch.caCert` and the secret will be
   constructed for you.


## Cassandra

Look in the [Cassandra
chart](https://artifacthub.io/packages/helm/bitnami/cassandra) for a
complete list of parameters you can set about the Cassandra
deployment. At this writing, this chart is built to either deploy
Cassandra itself, or not use Cassandra at all.

| Parameter                          | Description                                                         | Default |
| --                                 | --                                                                  | --      |
| cassandra.enabled                  | Set this to true to store TheHive main data in a Cassandra cluster. | false   |
| cassandra.persistence.storageClass | PVC Storage Class for Cassandra data volume                         | nil     |


## Cortex

TheHive can connect to one or more Cortex instances.

| Parameter      | Description                                                             | Default         |
| --             | --                                                                      | --              |
| cortex.enabled | Set this to true to hook up to some Cortex instances                    | false           |
| cortex.secret  | A secret with one or more Cortex instance URLs and respective API keys. | nil<sup>1</sup> |

Notes:

1. The named secret must be an opaque secret with a key "urls" whose
   value is the URL to one or more Cortex instances. If more than one,
   commas (but no spaces) separate the URLs. It must also have a key
   "keys" with one API key per URL, again separated by commas with no
   spaces.
