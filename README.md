# Unofficial Helm chart for TheHive

This repository contains a Helm chart that can install
[TheHive](https://thehive-project.org) 4, "security incident response
for the masses," onto a Kubernetes cluster.

## Trying it out

It's early days, but if you want to try it out, clone this repository,
cd into it, and

```
helm install .
```

You'll need to customize the values.yaml or provide some `--set`
command line options, of course. On my single-node home k3s 1.20.2
cluster with stock Traefik 1.7 and Helm 3.5.2, this does the trick for
me:

```
helm install -n thehive . \
             --set attachmentStorage.pvc.storageClass=local-path \
             --set 'ingress.hosts[0].host=hive.k.my.dns.domain' \
             --set 'ingress.hosts[0].paths[0].path=/'
```

## Improving it

If this chart doesn't flex in a way you need it to, and there isn't
already an issue about it, please file one.

If you can see your way to making an improvement, shoot a pull request
over.


## The future

I hope that one day this chart and its peers will be part of the
solution to https://github.com/TheHive-Project/TheHive/issues/1224. 
