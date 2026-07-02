fmt:
	terraform fmt -recursive

validate:
	cd terraform/environments/prod && terraform init -backend=false && terraform validate
	helm lint apps/pay-api-prod

render:
	helm template pay-api apps/pay-api-prod -f apps/pay-api-prod/values-prod.yaml
