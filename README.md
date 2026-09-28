# Nextcloud Docker Deployment with Terraform

This project uses Terraform to deploy a Nextcloud instance with a MySQL database using Docker containers. It is designed for local development and testing, leveraging the Docker and MySQL Terraform providers.

## Prerequisites
- [Docker](https://www.docker.com/) installed and running
- [Terraform](https://www.terraform.io/) installed (v1.4+ required)
- Docker CLI available on the machine running Terraform (for Nextcloud system settings)
- Access to the internet to pull Docker images

## Folder Structure
```
terraform/
  main.tf         # Provider and network configuration
  mysql.tf        # MySQL container and database setup
  nextcloud.tf    # Nextcloud container setup
  backup.tf       # Renders the backup/restore scripts
  backup/         # Backup/restore script templates
  var.tf          # Variable definitions
```

## Usage
For an isolated local test deployment, see [`test/README.md`](test/README.md).

1. **Clone the repository**
   ```sh
   git clone <repo-url>
   cd terraform-nextcloud/terraform
   ```
2. **Configure variables**
   Edit `var.tf` to set your Docker host, network, and other required variables.
3. **Initialize Terraform**
   ```sh
   terraform init
   ```
4. **Preview the deployment**
   ```sh
   terraform plan
   ```
5. **Apply the configuration**
   ```sh
   terraform apply
   ```
6. **Access Nextcloud**
   After deployment, Nextcloud will be available at the configured Docker host and port.

The Nextcloud maintenance window starts at 09:00 UTC by default (a four-hour
window), and the default phone region is `US`. Set `maintenance_window_start`
(an integer UTC hour from 0 to 23) and `default_phone_region` (a two-letter
ISO 3166-1 region code) in your Terraform inputs to customize them. Terraform
uses the Docker CLI to apply these settings via `occ` after Nextcloud is
installed; the CLI must be able to reach the Docker host configured for the
provider.

## Backup and Restore
`terraform apply` renders `nextcloud-backup.sh` and `nextcloud-restore.sh`, plus
Windows PowerShell versions `nextcloud-backup.ps1` and `nextcloud-restore.ps1`,
from the templates in `terraform/backup/` into `backup_install_path` (default
`../bin`, relative to the Terraform working directory). The scripts contain the
Nextcloud database password, so they are written with `0700` permissions and
ignored by Git.

The backup script stops the background worker and enables maintenance mode. It
then dumps the database and copies `backup_nextcloud_directories` (default
`config`, `data`, `themes`, and `custom_apps`) from the Nextcloud container. It
uploads a tar.gz archive to `s3://<backup_s3_bucket>/<backup_archive_name>`.
The bucket defaults to `organize-me.<domain>.backups`. The restore script
downloads that archive, replaces the database tables and directories, updates
the data fingerprint, and returns Nextcloud to normal operation.

The `.sh` scripts require a POSIX shell and Docker. The `.ps1` scripts require
only Docker and Windows PowerShell 5.1 or later; run them with
`powershell -ExecutionPolicy Bypass -File nextcloud-backup.ps1`. Both versions
produce the same archive format, so a backup made by one can be restored by the
other. MySQL, tar, and AWS CLI commands run
in containers (`backup_docker_mysql_image` and `backup_docker_aws_image`) on the
Nextcloud Docker network. AWS credentials come from `~/.aws` or from these
environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
`AWS_SESSION_TOKEN`, `AWS_DEFAULT_REGION`, `AWS_REGION`, and `AWS_PROFILE`. Set
`AWS_S3_ENDPOINT_URL` to use an S3-compatible endpoint. Any of these can also be
baked into the scripts as defaults with `backup_aws_environment`; values already
set in the environment take precedence. Temporary files are
created under `backup_tmp_dir` (default `../tmp`) and removed after each run.

Restoring replaces `config/config.php` with the backed-up copy, then reapplies
the target deployment's database connection settings from Terraform. Other
configuration remains from the backup, so restore into the same deployment or
review environment-specific settings (such as mail and trusted domains) before
using a backup in a different deployment.

## Providers Used
- [kreuzwerker/docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [bangau1/mysql](https://registry.terraform.io/providers/bangau1/mysql/latest/docs)
- [hashicorp/local](https://registry.terraform.io/providers/hashicorp/local/latest/docs)

## Customization
- Change variables in `var.tf` to customize network names, container settings, and credentials.
- Modify `nextcloud.tf` and `mysql.tf` for advanced container options.
