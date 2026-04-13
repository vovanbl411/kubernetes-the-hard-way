terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "k8s-the-hard-way/terraform.tfstate"
    region                      = "eu-central-1"

    endpoints = {
      s3 = "http://localhost:9000"
    }

    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}
