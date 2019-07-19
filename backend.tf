terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "cdunlap"

    workspaces {
      name = "hackathon-azure-vault"
    }
  }
}
