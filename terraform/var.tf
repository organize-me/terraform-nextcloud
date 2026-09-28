# General Variables
variable "timezone" {
  type    = string
  default = "America/Los_Angeles"
}
variable "install_root" {
  type        = string
  description = "Root directory for the installation"
}
variable "nextcloud_volume_name" {
  type        = string
  default     = null
  description = "Optional Docker volume for Nextcloud data instead of a host directory"
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
variable "smtp_secure" {
  type        = string
  default     = "tls"
  description = "SMTP transport security"
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
variable "mysql_endpoint" {
  type        = string
  description = "MySQL server endpoint"
}
variable "mysql_root_username" {
  type        = string
  default     = "root"
  description = "Root username for MySQL"
}
variable "mysql_root_password" {
  type        = string
  sensitive   = true
  description = "Root password for MySQL"
}

# Nextcloud Variables
variable "nextcloud_db_username" {
  type        = string
  description = "Database username for Nextcloud"
}
variable "nextcloud_db_password" {
  type        = string
  sensitive   = true
  description = "Database password for Nextcloud"
}
variable "nextcloud_username" {
  type        = string
  description = "Admin username for Nextcloud"
}
variable "nextcloud_password" {
  type        = string
  sensitive   = true
  description = "Admin password for Nextcloud"
}
variable "container_name_prefix" {
  type    = string
  default = "organize-me"
}
variable "nextcloud_port" {
  type    = number
  default = 8000
}
variable "nextcloud_bind_ip" {
  type        = string
  default     = null
  description = "Host IP for the Nextcloud published port; defaults to all interfaces"
}
variable "overwrite_protocol" {
  type    = string
  default = "https"
}
variable "trusted_domains" {
  type        = string
  default     = null
  description = "Space-separated Nextcloud trusted domains; defaults to nextcloud.<domain>"
}

variable "maintenance_window_start" {
  type        = number
  default     = 9
  description = "Start of the four-hour daily maintenance window, in UTC hours (0-23)"

  validation {
    condition     = var.maintenance_window_start >= 0 && var.maintenance_window_start <= 23 && floor(var.maintenance_window_start) == var.maintenance_window_start
    error_message = "maintenance_window_start must be an integer UTC hour from 0 to 23."
  }
}

variable "default_phone_region" {
  type        = string
  default     = "US"
  description = "ISO 3166-1 alpha-2 region for phone numbers without a country code"

  validation {
    condition     = can(regex("^[A-Z]{2}$", var.default_phone_region))
    error_message = "default_phone_region must be a two-letter uppercase region code."
  }
}

# Backup/Restore Variables
variable "backup_docker_mysql_image" {
  description = "The Docker image used to back up and restore the MySQL database"
  type        = string
  default     = "mysql:8.0"
}

variable "backup_docker_aws_image" {
  description = "The Docker image used to copy the backup archive to and from AWS S3"
  type        = string
  default     = "amazon/aws-cli:2.18.9"
}

variable "backup_install_path" {
  description = "The path to install the backup/restore scripts"
  type        = string
  default     = "../bin"
}

variable "backup_database_file_name" {
  description = "The name of the database dump inside the backup archive"
  type        = string
  default     = "database.sql"
}

variable "backup_archive_name" {
  description = "The name of the backup archive"
  type        = string
  default     = "nextcloud-backup.tar.gz"
}

variable "backup_s3_bucket" {
  description = "The S3 bucket to store the backup archive; defaults to organize-me.<domain>.backups"
  type        = string
  default     = null
}

variable "backup_aws_environment" {
  description = "Default AWS settings baked into the backup/restore scripts; values already set in the environment take precedence"
  type        = map(string)
  default     = {}
  sensitive   = true

  validation {
    condition = alltrue([for k in keys(var.backup_aws_environment) : contains([
      "AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_SESSION_TOKEN", "AWS_DEFAULT_REGION",
      "AWS_REGION", "AWS_PROFILE", "AWS_S3_ENDPOINT_URL"
    ], k)])
    error_message = "Keys must be AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN, AWS_DEFAULT_REGION, AWS_REGION, AWS_PROFILE, or AWS_S3_ENDPOINT_URL."
  }
}

variable "backup_tmp_dir" {
  description = "The parent directory for temporary backup/restore files"
  type        = string
  default     = "../tmp"
}

variable "backup_nextcloud_directories" {
  description = "Directories under /var/www/html to back up and restore"
  type        = list(string)
  default     = ["config", "data", "themes", "custom_apps"]

  validation {
    condition     = alltrue([for directory in var.backup_nextcloud_directories : can(regex("^[A-Za-z0-9._-]+$", directory)) && !contains([".", ".."], directory)])
    error_message = "backup_nextcloud_directories must contain directory names directly under /var/www/html."
  }
}
