terraform {
  required_version = ">= 1.10.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }

  backend "oci" {
    bucket    = "terraform-state-bucket"
    namespace = "grqwg4rp3vmd"
    key       = "toggle-master/terraform.tfstate"
    region    = "sa-saopaulo-1"
  }
}
