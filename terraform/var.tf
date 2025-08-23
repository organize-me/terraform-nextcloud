# General Variables
variable "timezone" {
  type    = string
  default = "America/Los_Angeles"
}
variable "install_root" {
  type        = string
  description = "Root directory for the installation"
}
variable "domain" {
  type        = string
  description = "Domain name for the Nextcloud instance"
}

# SMTP Variables
variable "smtp_host" {
  type        = string
  description = "SMTP host for sending emails"
}
variable "smtp_port" {
  type        = number
  description = "SMTP port for sending emails"
}
variable "smtp_username" {
  type        = string
  description = "SMTP username for authentication"
}
variable "smtp_password" {
  type        = string
  sensitive   = true
  description = "SMTP password for authentication"
}

# Docker Variables
variable "docker_host" {
  default = "unix:///var/run/docker.sock"
}
variable "docker_network" {
  type = string
}

# MySQL Variables
variable "mysql_root_password" {
  type        = string
  sensitive   = true
  description = "Root password for MySQL"
}
variable "nextcloud_db_username" {
  type        = string
  description = "Database username for Nextcloud"
}
variable "nextcloud_db_password" {
  type        = string
  sensitive   = true
  description = "Database password for Nextcloud"
}

# Nextcloud Variables
variable "nextcloud_username" {
  type        = string
  description = "Admin username for Nextcloud"
}
variable "nextcloud_password" {
  type        = string
  sensitive   = true
  description = "Admin password for Nextcloud"
}
