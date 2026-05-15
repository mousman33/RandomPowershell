# Random PowerShell Things

A collection of random PowerShell scripts and utilities.



## Goose Prank
Installs the desktop goose app with a scheduled task and makes it very hard to get rid of
### Install
1. Open powershell as admin or regular user. 
2. Run below to download and execute the install script
``` powershell
curl.exe -L "https://github.com/mousman33/RandomPowershell/raw/refs/heads/main/gooseprank.ps1" -o gooseprank.ps1
get-content .\gooseprank.ps1 -raw | invoke-expression
remove-item .\gooseprank.ps1
```
3. Above should clean up the downloaded script but double check to hide your tracks

The install can be undone with:
```
.\gooseprank.ps1 -remove
```





