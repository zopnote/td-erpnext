# ERPNext easy setup- and managertool
````bash
$ sudo ./bin/td-erpnext --help

Tool for automize backups and the management of the erpnext service under linux.

Available commands:
fix         Apply some fixes to encounter issues.
start       Start the ERPNext-instance.
stop        Stops the running ERPNext-instance.
status      Status information about the installation and the manager.
uninstall   Removes the installation securely.
setup       Installs and starts frappe erpnext.
settings    Adjust the settings. To adjust settings related to backups, use the corresponding command.
backups     Manage backups.
Flags:
--help         Displays information about the command and its flags.
````
This project is a CLI tool for automating ERPNext management and backups on Ubuntu systems using Docker.
Its primary purpose is to streamline the setup of frappe_docker, trigger database backups, and archive site volumes to ensure data persistence.
The project target is to make it super easy to setup ERPNext with backups, for single-person to small companies under linux.

> The project is primarily tested and supported for the latest Ubuntu LTS

The automation logic is built using the Stepflow library, which organizes tasks into a structured sequence of steps for reliable execution and management in Dart similar to widgets in Flutter.

## Installation
The installation is straightforward.

### Install binaries
Download the latest binaries from [here](https://github.com/zopnote/td-erpnext/releases).
Extract them to the desired folder. Notice that you couldn't move the application after setup without reinstalling the systemd services.
````
td-erpnext/
├── bin
│    └── td-erpnext (executable)
├── conf.json
├── license.txt
└── readme.txt
````

### Verify the settings and set the backup directory
The executable required elevated privileges.\
Set backup directory on your host system:
````bash
$ sudo ./bin/td-erpnext settings --backup_dist=<absolute_path>
````
There are multiple settings to make. Notice, that the manager never sets the docker container name, current site, root password or port,
but it needs these parameter in order to connect to the underlying docker-hosted ERPNext application. The values are correct for ``v16.5.0`` of ``frappe/erpnext``.
If these credentials change in future versions and I don't actually support this project anymore, you have to change the values to ensure the functionality.
````bash
$ sudo ./bin/td-erpnext settings
connect_port: 8080
connect_site_name: frontend
connect_docker_container: frappe_docker_frontend_1
app_directory: erpnext
log_directory: logs
backup_src: /home/frappe/frappe-bench/sites/frontend/private/backups
backup_dist: /var/backups/erpnext
db_root_password: admin
````
> As of the current version, logs aren't implemented. You have to go to ``<app_directory>/frappe_docker/logs/`` to see the logs.
### Setup
Install ERPNext and start.
````bash
$ sudo ./bin/td-erpnext setup
````
Enable automatic backups:
````bash
$ sudo ./bin/td-erpnext backups on --interval=3d:10h (default is 2d)
````
You can always create a backup using:
````bash
$ sudo ./bin/td-erpnext backups create
````

````bash
$ sudo ./bin/td-erpnext status

Status information about the installation and the manager.
ERPNext-Installation: ✓ Running
Configuration: ✓ Valid
Services: (backup-scheduler) ✓ Installed (Period: 3d:10h), (start-on-boot) ✓ Installed
Tries to connect to: (container) frappe_docker_frontend_1, (port) 8080, (site) frontend
````
> If you found bugs or just need help, feel free to open an issue on github, i would like to help.

## Binaries from source
Super easy! Clone the repo, install the ``dart-sdk`` and run ``$ dart run build.dart`` or directly ``$ sudo dart run run.dart``.
The output will be located under ``out/<os>-<arch>/``. This is also the development cycle, change ``bin/`` & ``lib/`` and just build again.

