output "aws_account_id" {
  description = "AWS 계정 ID"
  value       = data.aws_caller_identity.current.account_id
}

# ---- ECR ----

output "tomcat_ecr_url" {
  description = "Tomcat ECR 레포지토리 URL"
  value       = aws_ecr_repository.tomcat.repository_url
}

output "nginx_ecr_url" {
  description = "Nginx ECR 레포지토리 URL"
  value       = aws_ecr_repository.nginx.repository_url
}

# ---- EKS ----

output "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "EKS API 서버 엔드포인트"
  value       = aws_eks_cluster.main.endpoint
}

output "kubeconfig_command" {
  description = "kubeconfig 업데이트 명령어"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "alb_controller_role_arn" {
  description = "ALB Controller IRSA Role ARN (Helm values에 사용)"
  value       = aws_iam_role.alb_controller.arn
}

output "ebs_csi_role_arn" {
  description = "EBS CSI Driver IRSA Role ARN"
  value       = aws_iam_role.ebs_csi.arn
}

# ---- Monitoring ----

output "loki_s3_bucket" {
  description = "Loki 로그 저장 S3 버킷 이름"
  value       = aws_s3_bucket.loki.bucket
}

output "tempo_s3_bucket" {
  description = "Tempo 트레이스 저장 S3 버킷 이름"
  value       = aws_s3_bucket.tempo.bucket
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC Role ARN → GitHub Secret AWS_DEPLOY_ROLE_ARN에 등록"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "loki_irsa_role_arn" {
  description = "Loki IRSA Role ARN (loki-values.yaml serviceAccount annotations에 사용)"
  value       = aws_iam_role.loki.arn
}

output "tempo_irsa_role_arn" {
  description = "Tempo IRSA Role ARN (tempo-values.yaml serviceAccount annotations에 사용)"
  value       = aws_iam_role.tempo.arn
}
