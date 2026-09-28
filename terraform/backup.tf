locals {
  backup_template_vars = {
    TF_ARCHIVE_NAME                    = var.backup_archive_name
    TF_DATABASE_BACKUP_NAME            = var.backup_database_file_name
    TF_S3_BACKUP_BUCKET                = coalesce(var.backup_s3_bucket, "organize-me.${var.domain}.backups")
    TF_MYSQL_IMAGE                     = var.backup_docker_mysql_image
    TF_AWS_CLI_IMAGE                   = var.backup_docker_aws_image
    TF_BACKUP_TMP_DIR                  = abspath(var.backup_tmp_dir)
    TF_DOCKER_NETWORK                  = data.docker_network.network.name
    TF_MYSQL_HOST                      = local.nextcloud_db_host
    TF_MYSQL_PORT                      = local.nextcloud_db_port
    TF_MYSQL_USER                      = mysql_user.nextcloud.user
    TF_MYSQL_PASSWORD                  = var.nextcloud_db_password
    TF_MYSQL_DATABASE                  = mysql_database.nextcloud.name
    TF_NEXTCLOUD_CONTAINER_NAME        = docker_container.nextcloud.name
    TF_NEXTCLOUD_WORKER_CONTAINER_NAME = docker_container.nextcloud_worker.name
    TF_NEXTCLOUD_IMAGE                 = docker_image.nextcloud.name
    TF_NEXTCLOUD_DIRECTORIES           = join(" ", var.backup_nextcloud_directories)
    TF_AWS_ENVIRONMENT                 = var.backup_aws_environment
  }
}

# Script to back up Nextcloud to S3
resource "local_sensitive_file" "backup_script" {
  filename        = "${var.backup_install_path}/nextcloud-backup.sh"
  content         = templatefile("${path.module}/backup/backup.sh.tftpl", local.backup_template_vars)
  file_permission = "0700"
}

# Script to restore Nextcloud from S3
resource "local_sensitive_file" "restore_script" {
  filename        = "${var.backup_install_path}/nextcloud-restore.sh"
  content         = templatefile("${path.module}/backup/restore.sh.tftpl", local.backup_template_vars)
  file_permission = "0700"
}

# Windows PowerShell versions of the backup and restore scripts
resource "local_sensitive_file" "backup_script_powershell" {
  filename        = "${var.backup_install_path}/nextcloud-backup.ps1"
  content         = templatefile("${path.module}/backup/backup.ps1.tftpl", local.backup_template_vars)
  file_permission = "0700"
}

resource "local_sensitive_file" "restore_script_powershell" {
  filename        = "${var.backup_install_path}/nextcloud-restore.ps1"
  content         = templatefile("${path.module}/backup/restore.ps1.tftpl", local.backup_template_vars)
  file_permission = "0700"
}
