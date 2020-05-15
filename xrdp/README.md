Scripts that will install xrdp and enable the needed settings to use the enhanced session mode in Hyper-V.

Linux VMs need the HvSocket to be active:

Type in PowerShell as admin:

Set-VM -VMName 'my VM Name' -EnhancedSessionTransportType HvSocket