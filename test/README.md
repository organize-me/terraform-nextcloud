# Local test stack

From the repository root on Windows, run:

```powershell
.\test\start.ps1
```

To destroy the test stack, run `.\test\stop.ps1`. This permanently deletes
the test containers, both data volumes, local credentials, and Terraform
state. Run `.\test\start.ps1` again for a fresh installation and new password.

The script requires Docker Desktop and Terraform (install with
`winget install --id Hashicorp.Terraform --exact`). It starts the Docker
daemon if needed, creates local-only test credentials on the first run,
starts MySQL, Mailpit, and S3Mock, applies the isolated `test/terraform/` configuration,
waits for Nextcloud, and prints the admin login. Rerunning it uses the
existing credentials and data. It also moves state and credentials from the
previous `test/` layout into `test/terraform/` if present.

The Terraform module applies a four-hour maintenance window starting at
09:00 UTC and sets the default phone region to US after Nextcloud installs.
Override these with `maintenance_window_start` (an hour from 0 to 23) and
`default_phone_region` (a two-letter country code) in the ignored
`test/terraform/local.auto.tfvars`. A changed setting is applied by Terraform
without replacing the containers.

Nextcloud: http://localhost:18000

Mailpit: http://localhost:18025

S3 (S3Mock): http://localhost:19090

## Backup and restore

`start.ps1` also renders the backup and restore scripts into `test/bin/` and
starts an S3Mock container. The container is reachable as `http://s3:9090`
on the test Docker network and creates the `organize-me.localhost.backups`
bucket on startup. Its objects live in a Compose volume and are deleted by
`stop.ps1`. S3Mock is pinned to 3.12.0 because newer releases reject uploads
from the `amazon/aws-cli:2.18.9` image the scripts use.

The test configuration bakes S3Mock's endpoint and dummy credentials into the
scripts through `backup_aws_environment`, so no AWS setup is needed. Run the
PowerShell scripts:

```powershell
powershell -ExecutionPolicy Bypass -File test\bin\nextcloud-backup.ps1
powershell -ExecutionPolicy Bypass -File test\bin\nextcloud-restore.ps1
```

Or run the shell scripts with Git's `sh`:

```powershell
$env:MSYS_NO_PATHCONV = '1'
& 'C:\Program Files\Git\bin\sh.exe' test/bin/nextcloud-backup.sh
& 'C:\Program Files\Git\bin\sh.exe' test/bin/nextcloud-restore.sh
```

`MSYS_NO_PATHCONV` stops Git's shell from rewriting container paths such as
`/tmp/backup`. Browse stored backups at
http://localhost:19090/organize-me.localhost.backups.

Only test services are created; state and credentials in `test/` are
ignored by Git. Never run Terraform from
the repository's top-level `terraform/` to manage this local test stack.
