resource "aws_eks_cluster" "example" {
  name     = "example"
  role_arn = aws_iam_role.eks_cluster_example.arn
  version  = "1.20"

  vpc_config {
    endpoint_public_access = true
    subnet_ids             = aws_subnet.example_private[*].id
  }

  kubernetes_network_config {
    service_ipv4_cidr = "172.20.0.0/16"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_example-AmazonEKSVPCResourceController,
  ]
}

resource "aws_iam_role" "eks_cluster_example" {
  name = "eks_cluster_example"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_example-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_example-AmazonEKSVPCResourceController" {
  role       = aws_iam_role.eks_cluster_example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

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
