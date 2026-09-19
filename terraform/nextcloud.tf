resource "docker_image" "nextcloud" {
  name         = "nextcloud:31.0.8-apache"
  keep_locally = true
}

resource "docker_container" "nextcloud" {
  image         = docker_image.nextcloud.image_id
  name          = "organize-me-nextcloud"
  hostname      = "nextcloud"
  restart       = "unless-stopped"
  network_mode  = "bridge"

  user = "33:33"

  env   = [
    "PHP_MEMORY_LIMIT=1G",
    "TZ=${var.timezone}",
    "MYSQL_HOST=mysql",
    "DB_PORT=3306",
    "MYSQL_USER=${var.nextcloud_db_username}",
    "MYSQL_PASSWORD=${var.nextcloud_db_password}",
    "MYSQL_DATABASE=nextcloud",
    "OVERWRITEPROTOCOL=https",
    "NEXTCLOUD_ADMIN_USER=${var.nextcloud_username}",
    "NEXTCLOUD_ADMIN_PASSWORD=${var.nextcloud_password}",
    "NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.${var.domain}",
    "SMTP_HOST=${var.smtp_host}",
    "SMTP_SECURE=tls",
    "SMTP_PORT=${var.smtp_port}",
    "SMTP_NAME=${var.smtp_username}",
    "SMTP_PASSWORD=${var.smtp_password}",
    "MAIL_FROM_ADDRESS=noreplay",
    "MAIL_DOMAIN=${var.domain}"
  ]
  volumes {
    container_path = "/var/www/html/"
    host_path      = "${var.install_root}/nextcloud/var/www/html"
  }
  networks_advanced {
    name    = data.docker_network.network.name
    aliases = ["nextcloud"]
  }
  ports {
    internal = 80
    external = 8000
  }

  depends_on = [
    mysql_grant.nextcloud,
    mysql_user.nextcloud,
    mysql_database.nextcloud
  ]
}

resource "docker_container" "nextcloud_worker" {
  image         = docker_image.nextcloud.image_id
  name          = "organize-me-nextcloud-worker"
  user          = "33:33"
  restart       = "unless-stopped"
  network_mode  = "bridge"

  command = ["php", "occ", "background-job:worker", "-v", "--interval", "10", "OC\\TaskProcessing\\SynchronousBackgroundJob"]

  env = [
    "PHP_MEMORY_LIMIT=1G",
    "TZ=${var.timezone}",
    "MYSQL_HOST=mysql",
    "DB_PORT=3306",
    "MYSQL_USER=${var.nextcloud_db_username}",
    "MYSQL_PASSWORD=${var.nextcloud_db_password}",
    "MYSQL_DATABASE=nextcloud"
  ]

  volumes {
    container_path = "/var/www/html/"
    host_path      = "${var.install_root}/nextcloud/var/www/html"
  }

  networks_advanced {
    name    = data.docker_network.network.name
    aliases = ["nextcloud-worker"]
  }

  depends_on = [
    docker_container.nextcloud
  ]

  cpu_shares = 512           # 50% priority relative to other containers
  memory     = 536870912     # 512 MB
}

