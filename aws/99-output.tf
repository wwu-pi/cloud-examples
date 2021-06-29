output "kubeconfig" {
  value = <<EOF
apiVersion: v1
kind: Config
preferences: {}
clusters:
  - name: example
    cluster:
      certificate-authority-data: ${aws_eks_cluster.example.certificate_authority[0].data}
      server: ${aws_eks_cluster.example.endpoint}
users:
  - name: example
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1alpha1
        command: aws
        args:
          - --region
          - us-east-1
          - eks
          - get-token
          - --cluster-name
          - ${aws_eks_cluster.example.name}
contexts:
  - name: example
    context:
      cluster: example
      user: example
current-context: example
EOF
}

output "ServiceAccount-aws-load-balancer-controller" {
  value = <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  labels:
    app.kubernetes.io/name: aws-load-balancer-controller
    app.kubernetes.io/component: controller
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.aws-load-balancer-controller.arn}
EOF
}

output "ServiceAccount-ebs-csi-controller-sa" {
  value = <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ebs-csi-controller-sa
  namespace: kube-system
  labels:
    app.kubernetes.io/name: aws-ebs-csi-driver
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.ebs-csi-controller-sa.arn}
EOF
}
