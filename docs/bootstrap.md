# Bootstrap

Ez a dokumentum a két repo összekötésének minimum lépésrendjét írja le.

Jelenlegi projektadatok:

- AWS account ID: `494313539566`
- AWS régió: `eu-central-1`

## 1. GitHub repo

1. Hozd létre a `pay-api-gitops` GitHub repót.
2. Állítsd be a remote-ot.
3. Commitold és pushold a kezdőállapotot.

Példa:

```bash
git remote add origin git@github.com:joemeszaros/devops-pay-api-gitops.git
git add .
git commit -m "feat: bootstrap pay-api gitops"
git push -u origin main
```

## 2. Terraform backend

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Jegyezd fel:

- S3 bucket név
- DynamoDB lock tábla név

## 3. Prod infrastruktúra

A `terraform/environments/prod` könyvtárban töltsd ki a `terraform.tfvars` fájlt:

- `cluster_version`
- `availability_zones`
- `github_org` (`joemeszaros`)
- `github_app_repo` (`devops-pay-api-app`)

Utána:

```bash
cd terraform/environments/prod
terraform init \
  -backend-config="bucket=<STATE_BUCKET>" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=eu-central-1" \
  -backend-config="dynamodb_table=<LOCK_TABLE>"
terraform apply
```

## 4. Kubectl kapcsolat az EKS-hez

```bash
aws eks update-kubeconfig --region eu-central-1 --name pay-api-prod
kubectl get nodes
```

## 5. Argo CD

Telepítsd az Argo CD hivatalos manifestet:

```bash
kubectl apply -f platform/argocd/install.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f clusters/prod/pay-api-prod-application.yaml
```

## 6. App repo OIDC role bekötése

A Terraform outputból vedd ki a `github_actions_role_arn` értéket, és állítsd be a `pay-api-app` repóban `AWS_ROLE_ARN` variable-ként.

## 7. Első deploy

1. Merge változás a `pay-api-app` repóban.
2. Release workflow image-et pushol ECR-be.
3. Workflow PR-t nyit ebben a repóban.
4. Merge után Argo CD deployol.

## 8. Demo elérés Load Balancer nélkül

Alapértelmezésben a szolgáltatás `ClusterIP`, ezért a legegyszerűbb demo-elérés:

```bash
kubectl port-forward -n pay-api-prod svc/pay-api 8080:80
```

Ezután helyben eléred:

```bash
curl http://127.0.0.1:8080/health
curl -X POST http://127.0.0.1:8080/payments/quote \
  -H 'content-type: application/json' \
  -d '{"amountMinor":15001,"currency":"HUF","installments":6}'
```

Ha később publikus elérés kell, a `service.type` visszaállítható `LoadBalancer` értékre.
