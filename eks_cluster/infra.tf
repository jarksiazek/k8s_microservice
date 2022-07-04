variable "environment" {
  description = "Deployment Environment"
  default = "jksiazek-eks"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for Public Subnet"
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "CIDR block for Private Subnet"
  default = ["10.1.3.0/24", "10.1.4.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "AZ in which all the resources will be deployed"
  default = ["eu-west-1a", "eu-west-1b"]
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "this" {
  cidr_block = "10.1.0.0/20"

  tags = {
    Name = "${var.environment}-cluster"
  }
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name        = "${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id
  count      = length(var.public_subnets_cidr)
  cidr_block = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-${element(var.availability_zones, count.index)}-public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this.id
  count      = length(var.private_subnets_cidr)
  cidr_block = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.availability_zones, count.index)

  tags = {
    Name = "${var.environment}-${element(var.availability_zones, count.index)}-private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-private-route-table"
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

resource "aws_iam_role" "this" {
  name = "${var.environment}-eks-cluster-role"

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

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.this.name
}

resource "aws_eks_cluster" "this" {
  name     = "${var.environment}-cluster"
  role_arn = aws_iam_role.this.arn

  vpc_config {
    subnet_ids = aws_subnet.public.*.id
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

resource "aws_iam_role" "node-group-role" {
  name = "${var.environment}-node-group-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.node-group-role.name
  for_each = toset( ["arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
                "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
                "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
              ])
  policy_arn = each.key
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.environment}-node-group"

  node_role_arn = aws_iam_role.node-group-role.arn
  subnet_ids    = aws_subnet.public.*.id
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  capacity_type = "SPOT"
  disk_size = 5
  instance_types = ["t3.small"]
}

output "endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

