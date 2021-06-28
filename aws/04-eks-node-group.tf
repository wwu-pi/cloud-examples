resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "example"
  node_role_arn   = aws_iam_role.eks_node_group_example.arn
  subnet_ids      = aws_subnet.example_private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_group_example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_group_example-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "eks_node_group_example" {
  name = "eks_node_group_example"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_group_example-AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_group_example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_example-AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_group_example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_group_example-AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_group_example.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
