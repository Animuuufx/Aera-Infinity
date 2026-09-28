# Server overlay

This folder contains only the Aera-owned integration layer for drathaxie/InfinityServer.

The upstream emulator is not vendored into this repository. Run the installer to clone the latest complete upstream main checkout separately and apply the Aera changes.

Normal installation does not require Administrator. Elevation is only useful if you want the installer to add Windows Firewall rules for TCP 6677 and 6678.

Requirements:

- Git available in the same PowerShell session
- Python 3.12+
- Windows 10/11 or Windows Server

Run from this folder with PowerShell:

powershell -ExecutionPolicy Bypass -File .\INSTALL_AERA_INFINITYSERVER.ps1
