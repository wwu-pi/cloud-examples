# Create Kubernetes Test Cluster Using kind

Create cluster:

```sh
$ cd into/this/directory
$ kind create cluster --name acse --config kind-config.yaml
$ kubectl get nodes
```

Install Ingress controller:

```sh
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
$ kubectl get pods -n ingress-nginx
```

Create example workload

```sh
$ kubectl apply -f workloads/whoami
$ kubectl apply -f workloads/wordpress

$ watch kubectl get all --all-namespaces
$ watch -n 0.2 curl -sS http://localhost/whoami
```

Delete cluster:

```sh
$ kind delete cluster --name acse
```
