Templates to use for the Hyper-V Gallery.

The JSON File Path musst be added to the registry.

1. Open regedit.exe
2. Navigate to Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\
3. Search for GalleryLocations and edit it (when the item is not available, create it "REG_MULTI_SZ"
4. Now add youre File Path. (as a sample C:\hyperv-gallery\myvm.JSON)

Hyper-V can also add JSON Files over http/https

The Stanstard VM Tamplates Address from Microsoft: https://go.microsoft.com/fwlink/?linkid=851584

For more Infos: https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/custom-gallery

More Infos for Files and JSON Paths:

VHD file stored on Azure Blob Storage:
https://STORAGE_ACCOUNT.blob.core.windows.net/RESOURCE_GROUP/FOLDER/FILENAME.vhdx

Local PC:
file://DRIVE:/FOLDER/FILENAME.vhdx

Notice that you should only use file URI if you are doing gallery only for yourself.

NAS or PC on local network:
http://192.168.2.106:8080/FOLDER/FILENAME.vhdx

Notice the port number in the URL shown: port 8080 should work if you have not changed other port assignments.

Use the Get-FileHash cmdlet in PowerShell to calculate the SHA256 hash for your file (required):
Get-FileHash -Path PATH\FILENAME -Algorithm SHA256
