# Create Kubernetes Test Cluster Using kind

Create cluster:

```sh
$ cd into/this/directory
$ kind create cluster --name acse --config kind-config.yaml

$ kubectl get nodes
$ kubectl get all --all-namespaces
```

Install Ingress controller:

```sh
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.46.0/deploy/static/provider/kind/deploy.yaml
$ kubectl get all -n ingress-nginx
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
