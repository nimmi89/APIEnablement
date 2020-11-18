terraform {
  backend "s3" {
    bucket  = "ops-technical-test-tf-backend"
    key     = "tfstate"
    region  = "ap-southeast-2"
    encrypt = true
  }
}


