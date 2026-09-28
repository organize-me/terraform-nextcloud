locals {
  nextcloud_db_host = "mysql"
  nextcloud_db_port = 3306
}

resource "docker_image" "nextcloud" {
  name         = "nextcloud:34.0.4-apache"
  keep_locally = true
}

resource "docker_container" "nextcloud" {
  image        = docker_image.nextcloud.image_id
  name         = "${var.container_name_prefix}-nextcloud"
  hostname     = "nextcloud"
  restart      = "unless-stopped"
  network_mode = "bridge"

  user = "33:33"

  env = [
    "PHP_MEMORY_LIMIT=1G",
    "TZ=${var.timezone}",
    "MYSQL_HOST=${local.nextcloud_db_host}",
    "DB_PORT=${local.nextcloud_db_port}",
    "MYSQL_USER=${var.nextcloud_db_username}",
    "MYSQL_PASSWORD=${var.nextcloud_db_password}",
    "MYSQL_DATABASE=${mysql_database.nextcloud.name}",
    "OVERWRITEPROTOCOL=${var.overwrite_protocol}",
    "NEXTCLOUD_ADMIN_USER=${var.nextcloud_username}",
    "NEXTCLOUD_ADMIN_PASSWORD=${var.nextcloud_password}",
    "NEXTCLOUD_TRUSTED_DOMAINS=${var.trusted_domains != null ? var.trusted_domains : "nextcloud.${var.domain}"}",
    "SMTP_HOST=${var.smtp_host}",
    "SMTP_SECURE=${var.smtp_secure}",
    "SMTP_PORT=${var.smtp_port}",
    "SMTP_NAME=${var.smtp_username}",
    "SMTP_PASSWORD=${var.smtp_password}",
    "MAIL_FROM_ADDRESS=noreplay",
    "MAIL_DOMAIN=${var.domain}"
  ]
  volumes {
    container_path = "/var/www/html/"
    host_path      = var.nextcloud_volume_name == null ? "${var.install_root}/nextcloud/var/www/html" : null
    volume_name    = var.nextcloud_volume_name
  }
  networks_advanced {
    name    = data.docker_network.network.name
    aliases = ["nextcloud"]
  }
  ports {
    internal = 80
    external = var.nextcloud_port
    ip       = var.nextcloud_bind_ip
  }

  depends_on = [
    mysql_grant.nextcloud,
    mysql_user.nextcloud,
    mysql_database.nextcloud
  ]
}

resource "docker_container" "nextcloud_worker" {
  image        = docker_image.nextcloud.image_id
  name         = "${var.container_name_prefix}-nextcloud-worker"
  user         = "33:33"
  restart      = "unless-stopped"
  network_mode = "bridge"

  command = ["php", "occ", "taskprocessing:worker", "--interval", "10", "--timeout", "300"]

  env = [
    "PHP_MEMORY_LIMIT=1G",
    "TZ=${var.timezone}",
    "MYSQL_HOST=${local.nextcloud_db_host}",
    "DB_PORT=${local.nextcloud_db_port}",
    "MYSQL_USER=${var.nextcloud_db_username}",
    "MYSQL_PASSWORD=${var.nextcloud_db_password}",
    "MYSQL_DATABASE=${mysql_database.nextcloud.name}"
  ]

  volumes {
    container_path = "/var/www/html/"
    host_path      = var.nextcloud_volume_name == null ? "${var.install_root}/nextcloud/var/www/html" : null
    volume_name    = var.nextcloud_volume_name
  }

  networks_advanced {
    name    = data.docker_network.network.name
    aliases = ["nextcloud-worker"]
  }

  depends_on = [
    docker_container.nextcloud
  ]

  lifecycle {
    ignore_changes = [
      memory_swap
    ]
  }

  cpu_shares  = 512       # 50% priority relative to other containers
  memory      = 536870912 # 512 MB
  memory_swap = 1073741824
}

resource "terraform_data" "nextcloud_system_settings" {
  triggers_replace = [
    docker_container.nextcloud.id,
    var.maintenance_window_start,
    var.default_phone_region,
  ]

  provisioner "local-exec" {
    interpreter = [
      "docker", "--host", var.docker_host, "exec", "--user", "33",
      docker_container.nextcloud.name, "sh", "-c",
    ]
    command = join(" ", [
      "attempts=0;",
      "until php occ status --output=json 2>/dev/null | grep -q '\"installed\":true'; do",
      "attempts=$((attempts + 1));",
      "if [ \"$attempts\" -ge 90 ]; then echo 'Nextcloud did not finish installing within three minutes' >&2; exit 1; fi;",
      "sleep 2;",
      "done;",
      "php occ config:system:set maintenance_window_start --type=integer --value=${var.maintenance_window_start} &&",
      "php occ config:system:set default_phone_region --value=${var.default_phone_region}",
    ])
  }
}
