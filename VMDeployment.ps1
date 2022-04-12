
Function Find-DiskExistence {
   Param(
       [Parameter(Mandatory=$true)]
       [String]$VMDisk
   )

   Process {
       $DiskList = Get-VMHardDiskDrive *

       Foreach($Disk in $DiskList) {
           $Test = $Disk.Path
           Write-Host "$Test`n" -ForegroundColor Yellow
           If($Disk.Path -eq $VMDisk) {

               Return "NA"
           } Else {
               Write-Host "Deployment of a new virtual machine started..." -ForegroundColor Cyan
               Return $VMDisk
           }
       }
   }
}

Function Save-Configuration {
   Param(
       [Parameter(Mandatory=$true)]
       [String]$VMName,
       [Parameter(Mandatory=$true)]
       [String]$VMRam,
       [Parameter(Mandatory=$true)]
       [String]$VMDisk,
       [Parameter(Mandatory=$true)]
       [String]$VMDiskSize,
       [Parameter(Mandatory=$true)]
       [String]$VMLocation,
       [Parameter(Mandatory=$true)]
       [Int16]$VMGeneration,
       [Parameter(Mandatory=$true)]
       [String]$VMIso,
       [Parameter(Mandatory=$true)]
       [String]$VMSwitchName
   )

   Process {
       $VMDisk = $VMDisk.Replace('"', '')
       $VMLocation = $VMLocation.Replace('"', '')
       $VMIso = $VMIso.Replace('"', '')
       $VMSwitchName = $VMSwitchName.Replace('"', '')

       $VMValues = [PSCustomObject]@{
           Name = $VMName
           Ram = $VMRam
           DiskLocation = $VMDisk
           DiskSize = $VMDiskSize
           Location = $VMLocation
           Generation = $VMGeneration
           Iso = $VMIso
           SwitchName = $VMSwitchName
       }

       $VMConfig = [PSCustomObject]@{
           $VMName = $VMValues
       }

       $VMName = "$VMName"+".json"

       $ConfigPath = "F:\ESTIAM\M1 - ESTIAM\PIM\EasyCloud\VM\Config" + "\$VMName"

       $VMLocation = '"'+$VMLocation+'"'

       $VMConfig | ConvertTo-Json -Depth 2 | Out-File $ConfigPath
   }
}

Function Add-NewVM {
   Param(
       [Parameter(Mandatory=$true)]
       [String]$VMName,
       [Parameter(Mandatory=$true)]
       [String]$VMRam,
       [Parameter(Mandatory=$true)]
       [String]$VMDiskSize,
       [Parameter(Mandatory=$true)]
       [String]$VMOS,
       [Parameter(Mandatory=$true)]
       [String]$VMProcessor
   )

   Process {
       Try {
           $VMDisk = "F:\ESTIAM\M1 - ESTIAM\PIM\EasyCloud\VM\Storage\$VMName" + ".vhdx"
           $DiskChecker = Find-DiskExistence -VMDisk $VMDisk
           $VMPath = "F:\ESTIAM\M1 - ESTIAM\PIM\EasyCloud\VM\$VMName"
           $VMGeneration = 1
           $VMSwitchName = "Default Switch"
           $MachineCores = (Get-WmiObject Win32_processor | Select-Object NumberOfLogicalProcessors)

           Write-Host $DiskChecker

           If($DiskChecker -eq "NA") {
               Write-Warning "Disk with same name already exist"
               Write-Host "(x) Deployment failed" -ForegroundColor Red
               Break;
           }

           If($VMProcessor -gt $MachineCores.NumberOfLogicalProcessors) {
               Write-Warning "Number of virtual cores attributed are outpassing physical server number"
               Write-Host "(x) Deployment failed" -ForegroundColor Red
               Break;
           }

           $Command = "New-VM -Name $VMName -MemoryStartupBytes $VMRam -NewVHDPath '$VMDisk' -NewVHDSizeBytes $VMDiskSize -Path "+ "'$VMPath' " + "-Generation $VMGeneration -SwitchName '$VMSwitchName'"

           Invoke-Expression $Command

           Try {
               Switch($VMOS) {
                   'Windows' { $VMIsoPath = 'F:\Fichier ISO\Windows.iso' }
                   'Linux' { $VMIsoPath = 'F:\ESTIAM\M1 - ESTIAM\PIM\EasyCloud\ISO\Linux' }
                   Default { $VMIsoPath = 'Notfound'}
               }

               Add-VMDvdDrive -VMName $VMName -Path $VMIsoPath
               Set-VMProcessor $VMName -Count $VMProcessor
               Write-Host "(/) Sucessful verification" -ForegroundColor Green
           } Catch {
               Write-Warning "(x) Verification failed"
               Break;
           }

           Write-Host "(/) Sucessful deployment" -ForegroundColor Green

           Try {
               $Save = 'Save-Configuration -VMName $VMName -VMRam $VMRam -VMDisk "$VMDisk" -VMDiskSize $VMDiskSize -VMLocation "$VMPath" -VMGeneration $VMGeneration -VMIso $VMOS -VMSwitchName $VMSwitchName'
               Invoke-Expression $Save
               Write-Host "(i) Configuration file have been saved in the following folder " -ForegroundColor Cyan -NoNewline
               Write-Host "F:\ESTIAM\M1 - ESTIAM\PIM\EasyCloud\VM\Config" -BackgroundColor White -ForegroundColor DarkYellow
               Write-Host " "
           } Catch {
               Write-Warning "The configuration haven't been saved "
           }

       } Catch {
           Write-Warning "An error occured in the execution"
           Write-Host "(x) Deployment failed" -ForegroundColor Red
       } 
   }
}

Function Uninstall-VM {
   Param(
       [Parameter(Mandatory=$true)]
       [String]$VMName
   )

   Process {
       Try {
           $VMToDelete = Get-VM | Where-Object {$_.Name -like $VMName}

       } Catch {}
   }
}

Add-NewVM -VMName "Test" -VMRam 2GB -VMDiskSize 100GB -VMOS Windows -VMProcessor 1
