# Nextcloud Docker Deployment with Terraform

This project uses Terraform to deploy a Nextcloud instance with a MySQL database using Docker containers. It is designed for local development and testing, leveraging the Docker and MySQL Terraform providers.

## Prerequisites
- [Docker](https://www.docker.com/) installed and running
- [Terraform](https://www.terraform.io/) installed (v1.0+ recommended)
- Access to the internet to pull Docker images

## Folder Structure
```
terraform/
  main.tf         # Provider and network configuration
  mysql.tf        # MySQL container and database setup
  nextcloud.tf    # Nextcloud container setup
  var.tf          # Variable definitions
```

## Usage
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

## Providers Used
- [kreuzwerker/docker](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [bangau1/mysql](https://registry.terraform.io/providers/bangau1/mysql/latest/docs)

## Customization
- Change variables in `var.tf` to customize network names, container settings, and credentials.
- Modify `nextcloud.tf` and `mysql.tf` for advanced container options.



