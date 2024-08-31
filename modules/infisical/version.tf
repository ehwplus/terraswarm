terraform {

  required_version = "~> 1.2"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}
