# AWS Kubernetes Example

## Prerequisites

This example requires that the following commands are installed:

* `terraform`
* `aws`
* `kubectl`

Make sure to configure your AWS credentials in `~/.aws/credentials`:

```ini
[default]
region = us-east-1
aws_access_key_id = <key>
aws_secret_access_key = <secret>
aws_session_token = <token>
```

## Provision AWS resources

The following command can take several minutes to complete:

```sh
$ terraform init
$ terraform apply
```

## Configure `kubectl`

```sh
$ mkdir -p ~/.kube
$ mv ~/.kube/config ~/.kube/config.old
$ terraform output -raw kubeconfig > ~/.kube/config
```

## Install Kubernetes Cluster Components

Install controller for load balancer and ingress:

```sh
$ kubectl apply -f ingress
$ terraform output -raw ServiceAccount-aws-load-balancer-controller | kubectl apply -f -
```

Install controller for block storage

```sh
$ kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.1"
$ terraform output -raw ServiceAccount-ebs-csi-controller-sa | kubectl apply -f -
```

## Deploy Workloads

```sh
$ kubectl apply -f workloads/whoami
$ kubectl apply -f workloads/wordpress
```

## Delete Resources

```sh
$ kubectl delete -f workloads/whoami
$ kubectl delete -f workloads/wordpress

$ terraform destroy
$ mv ~/.kube/config.old ~/.kube/config
```
