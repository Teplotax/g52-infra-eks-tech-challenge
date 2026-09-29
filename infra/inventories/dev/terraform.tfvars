environment               = "dev"
cluster_name              = "eks-tech-challenge"
kubernetes_version        = "1.34"
aws_region                = "us-east-1"
app_namespace             = "tech-challenge"
subnet_ids                = ["subnet-0826d998a97492788", "subnet-0f8545b2a7f5196a2"]
console_user_arn          = ["arn:aws:iam::679084116705:user/Teplotaxl", "arn:aws:iam::679084116705:user/Teacher"]
destroy                   = false