# g52-infra-eks-tech-challenge

Infraestrutura Terraform para provisionamento de um **EKS Cluster (Fargate)** na AWS, com repositórios ECR, AWS Load Balancer Controller e metrics-server para autoscaling. Projeto do Grupo 52 para o Tech Challenge.

## Recursos provisionados

| Recurso | Descrição |
|---|---|
| `module.eks` (`terraform-aws-modules/eks/aws`) | Cluster EKS com Fargate Profiles para os namespaces `kube-system` e `tech-challenge` |
| `aws_ecr_repository` (app) | Repositório ECR em `grupo52/tech-challenge/<cluster_name>` com scan automático de imagens |
| `aws_ecr_repository` (keycloak) | Repositório ECR em `grupo52/tech-challenge/<cluster_name>-keycloak` com scan automático de imagens |
| `aws_iam_role` + `aws_iam_policy` (lb_controller) | Role IRSA e policy oficial do AWS Load Balancer Controller |
| `helm_release` (aws-load-balancer-controller) | Controller que provisiona a NLB a partir de manifestos Kubernetes |
| `helm_release` (metrics-server) | Necessário para o HPA calcular utilização de CPU/memória |
| `aws_ec2_tag` | Tags de descoberta de subnet (`kubernetes.io/cluster/*`, `kubernetes.io/role/elb`) usadas pelo Load Balancer Controller |

## Estrutura

```
infra/
├── main.tf                        # Cluster EKS, ECR, IAM/IRSA, Load Balancer Controller, metrics-server
├── variables.tf                   # Declaração de variáveis
├── locals.tf                      # Locals e tags
├── providers.tf                   # Providers AWS + Kubernetes + Helm, backend S3
├── outputs.tf                     # Outputs do cluster, ECR e IAM
├── iam/
│   └── aws-load-balancer-controller-policy.json   # Policy oficial kubernetes-sigs (v2.14.1)
└── inventories/
    └── dev/
        └── terraform.tfvars       # Variáveis do ambiente dev
```

## Pré-requisitos

- Terraform >= 1.6
- AWS CLI configurado com permissões adequadas
- Bucket S3 para armazenar o estado remoto (`teplotax-terraform-state-dev`)
- Subnets com rota de saída para a internet (NAT Gateway ou VPC Endpoints para `ecr.api`, `ecr.dkr`, `s3`, `sts` e `eks`). Pods em Fargate não recebem IP público diretamente, diferente das tasks ECS Fargate usadas anteriormente, então sem uma dessas duas opções os pods não conseguem puxar imagens do ECR nem assumir roles via IRSA

## Variáveis principais

| Variável | Tipo | Descrição |
|---|---|---|
| `cluster_name` | string | Nome do cluster EKS e prefixo dos repositórios ECR |
| `kubernetes_version` | string | Versão do Kubernetes (default: `1.31`) |
| `environment` | string | Nome do ambiente (ex: `dev`) |
| `vpc_id` | string | ID da VPC |
| `subnet_ids` | list(string) | Subnets do cluster e dos Fargate Profiles |
| `app_namespace` | string | Namespace da aplicação (default: `tech-challenge`) |
| `aws_region` | string | Região AWS (default: `sa-east-1`) |
| `destroy` | bool | Se `true`, o pipeline executa `terraform destroy` |

## Outputs

| Output | Descrição |
|---|---|
| `cluster_name` | Nome do cluster EKS criado |
| `cluster_endpoint` | Endpoint da API do cluster |
| `cluster_certificate_authority_data` | CA do cluster (base64) |
| `oidc_provider_arn` | ARN do provider OIDC do cluster, usado para IRSA |
| `lb_controller_role_arn` | ARN da IAM role usada pelo AWS Load Balancer Controller |
| `app_repository_url` | URL do repositório ECR da aplicação |
| `keycloak_repository_url` | URL do repositório ECR do Keycloak |

## Pipeline CI/CD

O projeto usa três workflows GitHub Actions com promoção automática entre ambientes:

```
feature/** -> develop -> release/vX.X.X -> main
```

| Workflow | Gatilho | Ação |
|---|---|---|
| `1-feature-to-dev-pr.yml` | Push em `feature/**` | Abre PR automático para `develop` |
| `2-terraform-dev.yml` | Push/PR em `develop` | Executa `terraform plan` (PR) ou `apply/destroy` (push); cria branch e PR `release/vX.X.X` |
| `4-release-to-main.yml` | PR fechado em `release/**` | Abre PR automático da release para `main` |

A autenticação com a AWS é feita via **OIDC** (sem chaves estáticas). O role `github-actions-terraform-dev` precisa aceitar tanto o formato clássico quanto o formato imutável do `sub` claim (`repo:Teplotax@<owner_id>/*:*`), já que repositórios criados após 15/07/2026 usam o novo formato por padrão.

## Migração de ECS para EKS

Este repositório substitui o antigo `g52-infra-ecs-tech-challenge`. Principais mudanças:

- Compute passa de ECS Fargate para Fargate Profiles do EKS (sem Spot, já que EKS Fargate não suporta preço Spot)
- Não há mais VPC Link; a NLB anterior é substituída por um Service `type: LoadBalancer` provisionado pelo AWS Load Balancer Controller
- Os manifestos Kubernetes (Deployments, Services, ConfigMaps, Secrets, HPA) não vivem aqui: ficam em `/k8s` no repositório `g52-app-tech-challenge`, aplicados via `kubectl` no workflow de deploy daquele repositório