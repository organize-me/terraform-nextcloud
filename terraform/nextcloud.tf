resource "docker_image" "nextcloud" {
  name         = "nextcloud:27.1.3-apache"
  keep_locally = true
}

resource "docker_container" "nextcloud" {
  image         = docker_image.nextcloud.image_id
  name          = "organize-me-nextcloud"
  hostname      = "nextcloud"
  restart       = "unless-stopped"
  env   = [
    "TZ=${var.timezone}",
    "MYSQL_HOST=mysql",
    "DB_PORT=3306",
    "MYSQL_USER=${var.nextcloud_db_username.value}",
    "MYSQL_PASSWORD=${var.nextcloud_db_password.value}",
    "MYSQL_DATABASE=nextcloud",
    "OVERWRITEPROTOCOL=https",
    "NEXTCLOUD_ADMIN_USER=${var.nextcloud_username.value}",
    "NEXTCLOUD_ADMIN_PASSWORD=${var.nextcloud_password.value}",
    "NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.${var.domain}",
    "SMTP_HOST=${var.smtp_host.value}",
    "SMTP_SECURE=tls",
    "SMTP_PORT=${var.smtp_port.value}",
    "SMTP_NAME=${var.smtp_username.value}",
    "SMTP_PASSWORD=${var.smtp_password.value}",
    "MAIL_FROM_ADDRESS=noreplay",
    "MAIL_DOMAIN=${var.domain}"
  ]
  volumes {
    container_path = "/var/www/html/"
    host_path      = "${var.install_root}/nextcloud/var/www/html"
  }
  networks_advanced {
    name    = data.docker_network.organize_me_network.name
    aliases = ["nextcloud"]
    ipv4_address = "172.22.0.5"
  }
  ports {
    internal = 80
    external = 8000
  }
  depends_on = [mysql_grant.nextcloud, mysql_user.nextcloud, mysql_database.nextcloud]
}
