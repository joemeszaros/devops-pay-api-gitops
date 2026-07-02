module "eks" {
  source = "../../modules/eks"

  project_name         = var.project_name
  aws_region           = var.aws_region
  cluster_name         = var.cluster_name
  cluster_version      = var.cluster_version
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  github_org           = var.github_org
  github_app_repo      = var.github_app_repo
  github_environment   = var.github_environment
  ecr_repository_name  = var.ecr_repository_name
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "ecr_repository_url" {
  value = module.eks.ecr_repository_url
}

output "github_actions_role_arn" {
  value = module.eks.github_actions_role_arn
}
