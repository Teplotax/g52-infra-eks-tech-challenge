data "aws_subnet" "public" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_subnet.public[var.public_subnet_ids[count.index]].availability_zone

  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-private-${count.index}"
  })
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = local.common_tags
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_ids[0]
  tags          = local.common_tags

  depends_on = [aws_eip.nat]
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id
  tags   = merge(local.common_tags, { Name = "${var.cluster_name}-private-rt" })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = aws_subnet.private[*].id

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true
  authentication_mode                      = "API_AND_CONFIG_MAP"

  fargate_profiles = {
    kube_system = {
      name = "kube-system"
      selectors = [
        { namespace = "kube-system" }
      ]
    }
    app = {
      name = var.app_namespace
      selectors = [
        { namespace = var.app_namespace }
      ]
    }
  }

  addons = {
    coredns = {
      configuration_values = jsonencode({
        computeType = "Fargate"
      })
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  tags = local.cluster_tags
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

resource "aws_ecr_repository" "app" {
  name = "grupo52/tech-challenge/${var.cluster_name}"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ecr_repository" "keycloak" {
  name = "grupo52/tech-challenge/${var.cluster_name}-keycloak"

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ec2_tag" "public_cluster_shared" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "public_elb_role" {
  for_each    = toset(var.public_subnet_ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_cluster_shared" {
  for_each    = { for idx, s in aws_subnet.private : tostring(idx) => s.id }
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

data "aws_iam_policy_document" "lb_controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "${var.cluster_name}-lb-controller"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role.json
  tags               = local.cluster_tags
}

resource "aws_iam_policy" "lb_controller" {
  name   = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = file("${path.module}/iam/aws-load-balancer-controller-policy.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  values = [
    yamlencode({
      clusterName = module.eks.cluster_name
      region      = var.aws_region
      vpcId       = var.vpc_id
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.lb_controller.arn
        }
      }
    })
  ]

  depends_on = [module.eks, aws_iam_role_policy_attachment.lb_controller]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  values = [
    yamlencode({
      args = ["--kubelet-insecure-tls"]
    })
  ]

  depends_on = [module.eks]
}
