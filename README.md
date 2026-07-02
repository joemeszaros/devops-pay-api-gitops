# pay-api-gitops

Külön repo a `pay-api` mintaalkalmazás AWS infrastruktúra- és GitOps-oldalához.

## Tartalom

- `bootstrap/`: egyszer futtatható Terraform a state backendhez
- `terraform/`: ECR, EKS, IAM alapok
- `platform/argocd/`: Argo CD telepítési erőforrások
- `apps/pay-api-prod/`: Helm chart a futtatott alkalmazáshoz
- `clusters/prod/`: Argo CD `Application` manifest a prod környezethez

## Működési modell

1. Az `pay-api-app` repo `main` merge után image-et pushol ECR-be.
2. Ugyanaz a workflow PR-t nyit ebben a repóban.
3. A PR az új image digestet írja be a `apps/pay-api-prod/values-prod.yaml` fájlba.
4. Merge után az Argo CD autosync deployolja a változást az EKS klaszterre.

## Alap futtatási sorrend

```bash
# 1. Terraform backend
cd bootstrap
terraform init
terraform apply

# 2. Infrastruktúrára
cd ../terraform/environments/prod
terraform init
terraform apply

# 3. Argo CD és app sync
kubectl apply -n argocd -f ../../platform/argocd/install.yaml
kubectl apply -f ../../clusters/prod/pay-api-prod-application.yaml
```

Részletes lépésrend: [docs/bootstrap.md](docs/bootstrap.md)

## Fontos feltételezések

- egyetlen AWS account
- egyetlen `prod` környezet
- külön GitHub repo az alkalmazásnak és a GitOpsnak
- GitHub OIDC role a release workflow számára
- a Kubernetes verzió nincs hardcode-olva, `terraform.tfvars`-ban kell megadni aktuális EKS támogatott verzióra
- a külső elérést v1-ben egy `Service type=LoadBalancer` adja, nem külön ingress controller
