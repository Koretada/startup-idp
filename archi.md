## Architecture globale

```text
AWS Cloud
├── S3 Backend (Remote State Terraform + DynamoDB State Lock)
├── S3 App Bucket (Stockage applicatif)
├── SQS Queue (Messages traités par le microservice)
├── IAM Instance Profile (Droits AWS accordés à l'EC2 sans clé secrète)
│
└── VPC Public (1 Subnet, 1 Internet Gateway)
      │
      └── EC2 t3.medium (Ubuntu 24.04 / Amazon Linux 2023)
            │
            └── K3s Cluster (Single-Node durci)
                  |
                  └── ArgoCD (GitOps Engine)
                        ├── Kube-Prometheus-Stack (Prometheus, Grafana, Alertmanager)
                        ├── Flagger (Progressive Delivery Operator)
                        ├── Ingress NGINX (Reverse proxy & Traffic Splitter)
                        └── Microservice applicatif (Consomme S3 & SQS via IAM)
```
