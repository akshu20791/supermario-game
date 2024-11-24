# Get VPC data
data "aws_vpc" "default" {
  default = true
}

# Get all subnets for the VPC
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Filter public subnets excluding us-east-1e
data "aws_subnet" "filtered" {
  for_each = toset(data.aws_subnets.all.ids)
  id       = each.value
}

# Helper: List of supported availability zones
data "aws_availability_zones" "supported" {}

# Filter subnets to exclude us-east-1e
locals {
  valid_subnets = [for subnet in data.aws_subnet.filtered : subnet.id if subnet.availability_zone != "us-east-1e"]
}

# Provision EKS cluster
resource "aws_eks_cluster" "example" {
  name     = "EKS_CLOUD"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = local.valid_subnets
  }

  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
  ]
}

# Remaining configuration remains unchanged
resource "aws_iam_role" "example" {
  name = "eks-cluster-cloud"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
