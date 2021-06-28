# AWS Kubernetes Example

## Prerequisites

This example requires that the following commands are installed:

* `terraform`
* `aws`
* `kubectl`

Make sure to configure your AWS credentials in `~/.aws/credentials`:

```ini
[aws]
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

## Delete AWS resources

```sh
$ terraform destroy
$ mv ~/.kube/config.old ~/.kube/config
```
