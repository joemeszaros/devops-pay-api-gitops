# Hallgatói útmutató a `pay-api` mintaalkalmazáshoz

Ez a dokumentum egyetlen, lépésről lépésre követhető útmutatóként szolgál. A célja, hogy a hallgató önállóan végig tudjon menni a helyi futtatáson, a GitHub-integráción, az AWS-infrastruktúrán, az Argo CD telepítésen és a Jaeger demón.

## 0. Mit kapsz a végén?

Két mikroszolgáltatásos mintarendszert:

- `pay-api`
- `currency-exchange`

amely:

- GitHub Actionsből buildel;
- Amazon ECR-be pushol image-eket;
- GitOps módon, külön repón keresztül deployol;
- Amazon EKS klaszterben fut;
- Jaegerrel trace-elhető.

## 0.1. Architektúraábra

![A pay-api mikroszolgáltatásos architektúrája](12-pay-api-architecture-diagram.png)

## 1. Előfeltételek

Szükséged lesz:

- GitHub-fiókra;
- AWS accountre;
- `git`;
- `node` és `npm`;
- `terraform`;
- `kubectl`;
- működő AWS CLI bejelentkezésre;
- két külön GitHub repóra:
  - `<APP_REPOSITORY_NAME>`
  - `<GITOPS_REPOSITORY_NAME>`

## 2. Helyi futtatás

Az alkalmazásrepóban:

```bash
npm install
npm test
npm run build
```

Ezután két terminálban:

```bash
# 1. terminál
npm run dev:currency-exchange

# 2. terminál
CURRENCY_EXCHANGE_BASE_URL=http://127.0.0.1:3100 npm run dev
```

Teszt:

```bash
curl -X POST http://127.0.0.1:3000/payments/quote \
  -H 'content-type: application/json' \
  -d '{"amountMinor":15001,"currency":"USD","outputCurrency":"GBP","installments":6}'
```

## 3. GitHub repo-k létrehozása

Hozd létre:

- `git@github.com:<GITHUB_ORG>/<APP_REPOSITORY_NAME>.git`
- `git@github.com:<GITHUB_ORG>/<GITOPS_REPOSITORY_NAME>.git`

Pushold fel mindkét helyi repót a saját remote-jára.

## 4. Alkalmazásrepó GitHub beállításai

Az alkalmazásrepóban hozd létre:

- `prod` environment

Variables:

- `AWS_REGION=<AWS_REGION>`
- `AWS_ROLE_ARN=arn:aws:iam::<AWS_ACCOUNT_ID>:role/<GITHUB_ACTIONS_ROLE_NAME>`
- `ECR_REPOSITORY=<ECR_REPOSITORY_NAME>`
- `GITOPS_REPOSITORY=<GITHUB_ORG>/<GITOPS_REPOSITORY_NAME>`
- `GITOPS_VALUES_FILE=apps/pay-api-prod/values-prod.yaml`

Secrets:

- `GITOPS_REPO_TOKEN`

## 5. GitOps repó előkészítése

A GitOps repóban keresd meg a placeholder értékeket, és cseréld ki őket a saját értékeidre.

Különösen ezekben a fájlokban:

- `bootstrap/terraform.tfvars.example`
- `terraform/environments/prod/terraform.tfvars.example`
- `clusters/prod/pay-api-prod-application.yaml`
- `clusters/prod/currency-exchange-prod-application.yaml`
- `clusters/prod/jaeger-application.yaml`
- `apps/pay-api-prod/values*.yaml`
- `apps/currency-exchange-prod/values*.yaml`

## 6. Terraform backend

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

Jegyezd fel:

- `<STATE_BUCKET_NAME>`
- `<LOCK_TABLE_NAME>`

## 7. Prod infrastruktúra

```bash
cd ../terraform/environments/prod
cp terraform.tfvars.example terraform.tfvars
```

Töltsd ki a placeholder értékeket, majd:

```bash
terraform init \
  -backend-config="bucket=<STATE_BUCKET_NAME>" \
  -backend-config="key=prod/terraform.tfstate" \
  -backend-config="region=<AWS_REGION>" \
  -backend-config="dynamodb_table=<LOCK_TABLE_NAME>"

terraform apply
```

## 8. Kubeconfig frissítése

```bash
aws eks update-kubeconfig --region <AWS_REGION> --name pay-api-prod
kubectl get nodes
```

## 9. Argo CD telepítése

```bash
kubectl apply -f platform/argocd/namespace.yaml
kubectl apply -f platform/argocd/install.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

## 10. Argo CD applicationök telepítése

```bash
kubectl apply -f clusters/prod/jaeger-application.yaml
kubectl apply -f clusters/prod/currency-exchange-prod-application.yaml
kubectl apply -f clusters/prod/pay-api-prod-application.yaml
```

Ellenőrzés:

```bash
kubectl get application -n argocd
kubectl get pods -n argocd
kubectl get pods -n observability
kubectl get pods -n pay-api-prod
```

## 11. Belépés az Argo CD felületre

Lokális eléréshez indíts port-forwardot:

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

Ezután nyisd meg böngészőben:

- `https://127.0.0.1:8081`

Első belépéshez:

- felhasználónév: `admin`
- kezdeti jelszó lekérése:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode
echo
```

Sikeres belépés után érdemes az admin jelszót az Argo CD felületén megváltoztatni.

## 12. Első release

Az alkalmazásrepóban merge-elj egy változást a `main` ágra.

Ekkor a release workflow:

1. buildeli a két image-et;
2. pusholja őket ECR-be;
3. pull requestet nyit a GitOps repóban;
4. a GitOps PR merge után Argo CD deployol.

## 13. Demo és ellenőrzés

```bash
kubectl port-forward -n pay-api-prod svc/pay-api 8080:80
kubectl port-forward -n observability svc/jaeger 16686:16686
```

API-teszt:

```bash
curl -i \
  -X POST http://127.0.0.1:8080/payments/quote \
  -H 'content-type: application/json' \
  -d '{"amountMinor":15001,"currency":"HUF","outputCurrency":"EUR","installments":6}'
```

Jaeger UI:

- `http://127.0.0.1:16686`

## 14. Mit ne commitolj?

Ne kerüljön követett fájlba:

- `terraform.tfvars`
- AWS access key
- AWS secret key
- GitHub token
- személyes AWS account ID fix példaként
- személyes GitHub orgnév vagy felhasználónév fix példaként

## 15. Rövid ellenőrzőlista

Ha valami nem működik, ezt nézd végig:

1. a placeholder értékeket mindenhol lecserélted;
2. a Terraform outputból kijött a role és a klaszter;
3. a kubeconfig az új klaszterre mutat;
4. az Argo CD podok `Running` állapotban vannak;
5. az Argo CD UI-ba be tudsz lépni az `admin` felhasználóval;
6. a kezdeti jelszót valóban a `argocd-initial-admin-secret` secretből kérted le;
7. a GitHub release workflow zöld;
8. a GitOps PR merge-elve van;
9. a `pay-api` és a `currency-exchange` podok valóban futnak;
10. a `kubectl port-forward` aktív;
11. a `pay-api` válaszban látszik az `x-trace-id`;
12. a Jaeger UI-ban megjelenik a trace.
