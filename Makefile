export GIT_SHA
export VERSION
export API_URL
DOCKER_RUN=docker-compose run --rm
TF_PLAN=ops-technical-test.tfplan
GIT_SHA=$(shell git rev-parse --short HEAD)
VERSION=1.0
API_URL = $(shell $(DOCKER_RUN) terraform output api_endpoint)
S3_BUCKET=ops-technical-test-tf-backend

plan: init ssm-put
	$(DOCKER_RUN) terraform plan -out=$(TF_PLAN)
.PHONY: plan

deploy: init plan
	$(DOCKER_RUN) terraform apply $(TF_PLAN)
.PHONY: deploy

ssm-put:
	echo "Storing GIT_SHA and VERSION of your application"
	bash scripts/ssm-put.sh  

init:
	$(DOCKER_RUN) terraform init
.PHONY: init

tf-backend:
	$(DOCKER_RUNNER) aws s3 mb s3://${S3_BUCKET} --region ap-southeast-2


test:   
	bash scripts/test.sh $(API_URL)

clean:
	$(DOCKER_RUN) terraform destroy
.PHONY: clean
