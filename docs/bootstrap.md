# Bootstrap

Ez a dokumentum a két repo összekötésének minimum lépésrendjét írja le.

## 1. GitHub repo

1. Hozd létre a `pay-api-gitops` GitHub repót.
2. Állítsd be a remote-ot.
3. Commitold és pushold a kezdőállapotot.

Példa:

```bash
git remote add origin git@github.com:<ORG>/pay-api-gitops.git
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
- `github_org`
- `github_app_repo`

Utána:

```bash
cd terraform/environments/prod
terraform init \
  -backend-config="bucket=<STATE_BUCKET>" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=<AWS_REGION>" \
  -backend-config="dynamodb_table=<LOCK_TABLE>"
terraform apply
```

## 4. Kubectl kapcsolat az EKS-hez

```bash
aws eks update-kubeconfig --region <AWS_REGION> --name pay-api-prod
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
