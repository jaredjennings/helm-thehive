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

### Scalable data: Cassandra and ECK Elasticsearch

This is the same as the above, but storing data in Cassandra and
indexing using Elasticsearch. Make a `values-as-given.yaml`:

```yaml
ingress:
  hosts:
    - host: h2.k.my.dns.domain
      paths:
       - path: /
storageClass: local-path
elasticsearch:
  eck:
    enabled: true
    name: my-eck-cluster
cassandra:
  enabled: true
  persistence:
    storageClass: local-path
  dbUser:
    password: "my-super-secure-password"
```

#### Idempotence

You should specify a value for `cassandra.dbUser.password`. When the
Cassandra chart sets up Cassandra for the first time, it sets the
password as directed, defaulting to a random password. The password is
then saved in a Secret. Now if you `helm upgrade`, say, to change some
of your values, the Cassandra chart will make a new Secret, but the
persistent volume(s) where the password was set during initial setup -
and where the data lives! - won't get deleted. If you specified a
password, this all works fine; but if you let it default to something
random, the Secret will now contain a wrong password, and anything
obtaining the password from that Secret (e.g. TheHive as configured by
this chart) will fail to access Cassandra. So set the password. You
should change it periodically, but that task doesn't appear to be
handled for you by these charts.

#### Caveats

Upon first installation, TheHive may fail to connect to Cassandra for
a few minutes. Try waiting it out.


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

| Parameter                            | Description                                                            | Default                |
| ---------                            | -----------                                                            | -------                |
| elasticsearch.eck.enabled            | Set this to true if you used ECK to set up an Elasticsearch cluster.   | false                  |
| elasticsearch.eck.name               | Set to the name of the `Elasticsearch` custom resource.                | nil                    |
| elasticsearch.external.enabled       | Set this to true if you have a non-ECK Elasticsearch server/cluster.   | false                  |
| elasticsearch.username               | Username with which to authenticate to Elasticsearch.                  | elastic<sup>1,2</sup>  |
| elasticsearch.userSecret             | Secret containing the password for the named user.                     | nil<sup>1</sup>        |
| elasticsearch.url                    | URL to Elasticsearch server/cluster.                                   | nil<sup>1</sup>        |
| elasticsearch.tls                    | Set this to true to provide a CA cert to trust.                        | true<sup>1</sup>       |
| elasticsearch.caCertSecret           | Secret containing the CA certificate to trust.                         | nil<sup>1,3</sup>      |
| elasticsearch.caCertSecretMappingKey | Name of the key in the caCertSecret whose value is the CA certificate. | "ca.crt"<sup>1,3</sup> |
| elasticsearch.caCert                 | PEM text of the CA cert to trust.                                      | nil<sup>1,3</sup>      |

Notes:

1. If you use ECK to set up an Elasticsearch cluster, you don't need
   to specify this.
2. The user secret should be an opaque secret, with data whose key is
   the username and value is the password.
3. The `caCertSecret` should be an opaque secret with a key named by
   `caCertSecretMappingKey` whose value is the PEM-encoded
   certificate. It could have other keys and values. If you don't have
   such a secret already, you can provide the PEM-encoded certificate
   itself as the `elasticsearch.caCert` value, and the secret will be
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
