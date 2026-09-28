terraform {
  required_version = ">= 1.4.0"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "= 3.0.1"
    }
    mysql = {
      source  = "bangau1/mysql"
      version = "= 1.10.4"
    }
  }
}

resource "docker_volume" "nextcloud" {
  name = "terraform-nextcloud-test-data"
}

module "nextcloud" {
  source = "../../terraform"

  install_root             = "."
  nextcloud_volume_name    = docker_volume.nextcloud.name
  domain                   = "localhost"
  docker_host              = var.docker_host
  docker_network           = "terraform-nextcloud-test"
  mysql_endpoint           = "127.0.0.1:33306"
  mysql_root_password      = var.mysql_root_password
  nextcloud_db_username    = "nextcloud_test"
  nextcloud_db_password    = var.nextcloud_db_password
  nextcloud_username       = "admin"
  nextcloud_password       = var.nextcloud_password
  smtp_host                = "mailpit"
  smtp_port                = 1025
  smtp_username            = ""
  smtp_password            = ""
  smtp_secure              = ""
  container_name_prefix    = "organize-me-test"
  nextcloud_port           = 18000
  nextcloud_bind_ip        = "127.0.0.1"
  overwrite_protocol       = "http"
  trusted_domains          = "localhost:18000 127.0.0.1:18000"
  maintenance_window_start = var.maintenance_window_start
  default_phone_region     = var.default_phone_region
  backup_s3_bucket         = "organize-me.localhost.backups"

  # S3Mock accepts any credentials; the AWS CLI just needs some to be set.
  backup_aws_environment = {
    AWS_ACCESS_KEY_ID     = "test"
    AWS_SECRET_ACCESS_KEY = "test"
    AWS_DEFAULT_REGION    = "us-east-1"
    AWS_S3_ENDPOINT_URL   = "http://s3:9090"
  }
}
