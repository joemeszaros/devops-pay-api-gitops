output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "ecr_repository_url" {
  value = aws_ecr_repository.pay_api.repository_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_release.arn
}
