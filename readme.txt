td_erpnext

This project is a CLI tool for automating ERPNext instance management and backups on Ubuntu systems using Docker. 
Its primary purpose is to streamline the setup of frappe_docker, trigger database backups, and archive site volumes to ensure data persistence.

The automation logic is built using the Stepflow library, which organizes tasks into a structured sequence of steps for reliable execution and management in Dart similar to widgets in Flutter.

The project runs on Linux, tested on Ubuntu.
To build and run the project binaries, just clone the repository, run dart pub get and sudo dart run build/run.dart inside the projects root.
