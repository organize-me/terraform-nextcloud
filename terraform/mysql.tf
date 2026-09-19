provider "mysql" {
  endpoint = var.mysql_endpoint
  username = var.mysql_root_username
  password = var.mysql_root_password
}

resource "mysql_database" "nextcloud" {
  default_character_set = "utf8mb3"
  default_collation     = "utf8mb3_general_ci"
  name                  = "nextcloud"
}

resource "mysql_user" "nextcloud" {
  user               = var.nextcloud_db_username
  host               = "%"
  plaintext_password = var.nextcloud_db_password
}

resource "mysql_grant" "nextcloud" {
  user = mysql_user.nextcloud.user
  host = mysql_user.nextcloud.host
  database = mysql_database.nextcloud.name
  privileges = ["ALL PRIVILEGES"]
  depends_on = [mysql_user.nextcloud, mysql_database.nextcloud]
}

