variable "docker_host" {
  type        = string
  default     = "unix:///var/run/docker.sock"
  description = "Docker daemon URI (use npipe:////./pipe/docker_engine on Windows)"
}

variable "mysql_root_password" {
  type      = string
  sensitive = true
}

variable "nextcloud_db_password" {
  type      = string
  sensitive = true
}

variable "nextcloud_password" {
  type      = string
  sensitive = true
}

variable "maintenance_window_start" {
  type        = number
  default     = 9
  description = "Start of the four-hour maintenance window, in UTC hours (0-23)"

  validation {
    condition     = var.maintenance_window_start >= 0 && var.maintenance_window_start <= 23 && floor(var.maintenance_window_start) == var.maintenance_window_start
    error_message = "maintenance_window_start must be an integer UTC hour from 0 to 23."
  }
}

variable "default_phone_region" {
  type        = string
  default     = "US"
  description = "ISO 3166-1 alpha-2 region used for phone numbers without a country code"

  validation {
    condition     = can(regex("^[A-Z]{2}$", var.default_phone_region))
    error_message = "default_phone_region must be a two-letter uppercase region code."
  }
}
