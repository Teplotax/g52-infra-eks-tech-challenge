# g52-infra-ecs-tech-challenge

Infraestrutura Terraform para provisionamento de um **ECS Cluster (Fargate)** na AWS, com repositório ECR e VPC Endpoints privados para comunicação segura sem tráfego pela internet. Projeto do Grupo 52 para o Tech Challenge.

## Recursos provisionados

| Recurso | Descrição |
|---|---|
| `aws_ecs_cluster` | Cluster ECS com suporte a Container Insights configurável |
| `aws_ecs_cluster_capacity_providers` | Capacidade via `FARGATE_SPOT` (padrão) e `FARGATE` |
| `aws_ecr_repository` | Repositório ECR em `grupo52/tech-challenge/<ecs_name>` com scan automático de imagens |
| `aws_security_group` | Security Group para os VPC Endpoints (ingress HTTPS/443) |
| `aws_vpc_endpoint` (ecr.api) | VPC Endpoint Interface para a API do ECR |
| `aws_vpc_endpoint` (ecr.dkr) | VPC Endpoint Interface para pull de imagens Docker |
| `aws_vpc_endpoint` (s3) | VPC Endpoint Gateway para acesso ao S3 (layers do ECR) |

## Estrutura

```
infra/
├── main.tf                        # Recursos principais (ECS, ECR, VPC Endpoints, SG)
├── variables.tf                   # Declaração de variáveis
├── locals.tf                      # Locals e tags
├── providers.tf                   # Provider AWS + backend S3
├── outputs.tf                    # Outputs: cluster_id e cluster_name
└── inventories/
    └── dev/
        └── terraform.tfvars       # Variáveis do ambiente dev
```

## Pré-requisitos

- Terraform >= 1.6
- AWS CLI configurado com permissões adequadas
- Bucket S3 para armazenar o estado remoto (`teplotax-terraform-state-dev`)

## Variáveis principais

| Variável | Tipo | Descrição |
|---|---|---|
| `ecs_name` | string | Nome do cluster ECS e do repositório ECR |
| `environment` | string | Nome do ambiente (ex: `dev`) |
| `container_insights` | bool | Habilita Container Insights no cluster (default: `false`) |
| `vpc_id` | string | ID da VPC |
| `subnet_ids` | list(string) | Subnets para os VPC Endpoints Interface |
| `route_table_ids` | list(string) | Route tables para o VPC Endpoint Gateway (S3) |
| `cidr_blocks` | list(string) | CIDRs permitidos no Security Group |
| `aws_region` | string | Região AWS (default: `sa-east-1`) |
| `destroy` | bool | Se `true`, o pipeline executa `terraform destroy` |

## Outputs

| Output | Descrição |
|---|---|
| `cluster_id` | ID do cluster ECS criado |
| `cluster_name` | Nome do cluster ECS criado |

## Pipeline CI/CD

O projeto usa três workflows GitHub Actions com promoção automática entre ambientes:

```
feature/** → develop → release/vX.X.X → main
```

| Workflow | Gatilho | Ação |
|---|---|---|
| `1-feature-to-dev-pr.yml` | Push em `feature/**` | Abre PR automático para `develop` |
| `2-terraform-dev.yml` | Push/PR em `develop` | Executa `terraform plan` (PR) ou `apply/destroy` (push); cria branch e PR `release/vX.X.X` |
| `4-release-to-main.yml` | PR fechado em `release/**` | Abre PR automático da release para `main` |

A autenticação com a AWS é feita via **OIDC** (sem chaves estáticas).