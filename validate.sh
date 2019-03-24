#!/bin/sh

set -e

terraform validate -var-file config/account/microservice/staging/us-east-1.tfvars
terraform validate -var-file config/account/microservice/production/us-east-1.tfvars
terraform validate -var-file config/account/microservice/staging/ap-northeast-1.tfvars
terraform validate -var-file config/account/microservice/production/ap-northeast-1.tfvars
terraform validate -var-file config/account/microservice/staging/ap-southeast-1.tfvars
terraform validate -var-file config/account/microservice/production/ap-southeast-1.tfvars
terraform validate -var-file config/account/microservice/staging/eu-central-1.tfvars
terraform validate -var-file config/account/microservice/production/eu-central-1.tfvars
terraform validate -var-file config/account/ecweb/staging/us-east-1.tfvars
terraform validate -var-file config/account/ecweb/production/us-east-1.tfvars
terraform validate -var-file config/account/ecweb/staging/ap-northeast-1.tfvars
terraform validate -var-file config/account/ecweb/production/ap-northeast-1.tfvars
terraform validate -var-file config/account/ecweb/staging/ap-southeast-1.tfvars
terraform validate -var-file config/account/ecweb/production/ap-southeast-1.tfvars
terraform validate -var-file config/account/ecweb/staging/eu-central-1.tfvars
terraform validate -var-file config/account/ecweb/production/eu-central-1.tfvars