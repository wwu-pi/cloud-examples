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

data "tls_certificate" "example" {
  url = aws_eks_cluster.example.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_example" {
  url = aws_eks_cluster.example.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.example.certificates[0].sha1_fingerprint,
  ]
}
