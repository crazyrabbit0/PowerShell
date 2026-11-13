Restart-Service WFDSConMgrSvc, DeviceAssociationService -Force
Get-Service 'DevicesFlowUserSvc_*', 'DevicePickerUserSvc_*' | Restart-Service -Force
Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match '802\.11|Wireless LAN' } | Restart-NetAdapter
Read-Host 'Done - press Enter to close'