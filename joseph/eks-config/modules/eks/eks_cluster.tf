module "subnets_id"{
  source = "../vpc"


}
resource "aws_eks_cluster" "eks" {
  name     = "pc-eks"
  role_arn = aws_iam_role.master.arn


  vpc_config {
    subnet_ids = [module.subnets_id.pub_subnet_1, module.subnets_id.pub_subnet_2]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
    #aws_subnet.pub_sub1,
    #aws_subnet.pub_sub2,
  ]

}

resource "aws_instance" "kubectl-server" {
  ami                         = "ami-0fc5d935ebf8bc3bc"
  key_name                    = "aws_eks_cluster_master_key"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = module.subnets_id.pub_subnet_1
  vpc_security_group_ids      = [module.subnets_id.security_group]

  tags = {
    Name = "kubectl"
  }

}

resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "pc-node-group"
  node_role_arn   = aws_iam_role.worker.arn
  subnet_ids      = [module.subnets_id.pub_subnet_1, module.subnets_id.pub_subnet_2]
  capacity_type   = "ON_DEMAND"
  disk_size       = "20"
  instance_types  = ["t2.small"]

  remote_access {
    ec2_ssh_key               = "aws_eks_cluster_master_key"
    source_security_group_ids = [module.subnets_id.security_group]
  }

  labels = tomap({ env = "dev" })

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
    #aws_subnet.pub_sub1,
    #aws_subnet.pub_sub2,
  ]
}