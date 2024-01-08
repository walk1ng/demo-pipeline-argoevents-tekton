#!/bin/bash

https_proxy=http://192.168.56.1:7890
http_proxy=http://192.168.56.1:7890
no_proxy="localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,10.244.0.0/16,10.96.0.0/12,.svc,.cluster.local"

kubectl -n argocd create configmap proxy-config \
	--from-literal http_proxy="$http_proxy" \
	--from-literal HTTP_PROXY="$http_proxy" \
	--from-literal https_proxy="$https_proxy" \
	--from-literal HTTPS_PROXY="$https_proxy" \
	--from-literal no_proxy="$no_proxy" \
	--from-literal NO_PROXY="$no_proxy" 

kubectl patch -n argocd \
	-p '{ "spec": {"template": { "spec": { "containers": [ { "name": "argocd-repo-server", "envFrom": [ { "configMapRef": {"name": "proxy-config" } } ] } ] } } } }' \
       	deployment argocd-repo-server

