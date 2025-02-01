# Automated Server Setup Script

![Bash](https://img.shields.io/badge/Language-Bash-green)
![GitHub](https://img.shields.io/badge/Platform-Linux-blue)
![License](https://img.shields.io/badge/License-MIT-orange)

This repository contains a **Bash script** designed to automate the setup and configuration of a web server environment. It installs and configures essential components such as **Nginx**, **PHP 8.2**, **MySQL**, and **Composer**, making it ideal for quickly deploying a PHP-based web application.

---

## Features

- **Nginx Installation**: Installs and configures Nginx as the web server.
- **PHP 8.2 with Modules**: Installs PHP 8.2 along with commonly used extensions (e.g., MySQL, GD, Curl, Redis, etc.).
- **MySQL Setup**: Installs MySQL and secures it using `mysql_secure_installation`.
- **Composer Installation**: Automatically installs Composer for PHP dependency management.
- **Project Directory Setup**: Creates a project directory with proper permissions and adds a test `index.php` file.
- **Error Handling**: Includes robust error checking and logging to ensure smooth execution.
- **Colorful Output**: Provides clear, color-coded messages for better readability.
- **Logging**: Logs all script output to `/var/log/script.log` for debugging and reference.

---

## Why Use This Script?

- **Time-Saving**: Automates repetitive server setup tasks, saving you time and effort.
- **Consistency**: Ensures a consistent environment across multiple deployments.
- **Customizable**: Easily modify the script to suit your specific needs.
- **Beginner-Friendly**: Includes detailed comments and checks to guide users through the process.

---

## Requirements

- A Linux-based system (tested on Ubuntu).
- Root or sudo access.

---

## How to Use

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/your-repo-name.git
