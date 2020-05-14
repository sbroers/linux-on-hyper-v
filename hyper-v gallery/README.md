Templates to use for the Hyper-V Gallery.

The JSON File Path musst be added to the registry.

1. Open regedit.exe
2. Navigate to Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\
3. Search for GalleryLocations and edit it (when the item is not available, create it "REG_MULTI_SZ"
4. Now add youre File Path. (as a sample C:\hyperv-gallery\myvm.JSON)

Hyper-V can also add JSON Files over http/https

The Stansrd VM Tamplates Address from Microsoft: https://go.microsoft.com/fwlink/?linkid=851584
