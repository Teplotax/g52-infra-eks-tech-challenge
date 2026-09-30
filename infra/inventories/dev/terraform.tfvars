environment               = "dev"
cluster_name              = "eks-tech-challenge"
kubernetes_version        = "1.34"
aws_region                = "us-east-1"
app_namespace             = "tech-challenge"
subnet_ids                = ["subnet-0f8545b2a7f5196a2", "subnet-0f211081d9ccab538"]
console_user_arn          = ["arn:aws:iam::679084116705:user/Teplotaxl", "arn:aws:iam::679084116705:user/Teacher"]
destroy                   = true