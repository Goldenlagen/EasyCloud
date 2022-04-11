Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function Invoke-Initialization {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'EasyCloud Installer'
    $form.Size = New-Object System.Drawing.Size(300,200)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = "White"

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(50,120)
    $okButton.Size = New-Object System.Drawing.Size(100,23)
    $okButton.Text = 'Start Installation'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $image1 = New-Object System.Windows.Forms.pictureBox
    $image1.Location = New-Object Drawing.Point 40,40
    $image1.Size = New-Object System.Drawing.Size(100,100)
    $image1.image = [system.drawing.image]::FromFile("./EasyCloudLogo.png")
    $form.controls.add($image1)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(160,120)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Exit'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $form.Topmost = $true
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
        Return Initialize-Install
    } else {
        Write-Host "Installation cancelled"
        Break;
    }
}

Function Initialize-Install {
    Begin {
        Write-Host "App installation will start..." -ForegroundColor Cyan
    }

    Process {
        Function Get-Folder($initialDirectory="")
        {
            Add-Type -AssemblyName System.Windows.Forms

            $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
            $FolderBrowser.Description = 'Select the folder containing the data'
            $result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
            
            if ($result -eq [Windows.Forms.DialogResult]::OK){
                $FolderBrowser.SelectedPath
            } else {
                exit
            }

            return $folder
        }

        $folder = Get-Folder

        If ($folder)
        {
            Write-Host "App will be installed in: " $folder
            Return $folder
        } Else {
            Write-Warning "Something wrong happened"
            Read-Host "Press enter to exit"
            Break;
        }
    }
}

Function Add-FolderStructure {
    Param(
        [Parameter(Mandatory=$true)]
        $mainPath
    )

    Process {
        $mainPath.getType()
        $foldersToCreate = @(
            'App',
            'Configuration',
            'VirtualMachines'
        )

        $subFoldersToCreate = @(
            @{'App' = 'PSScript'},
            @{'Configuration' = 'Default'},
            @{'Configuration' = 'VirtualMachines'}
        )
        
        $foldersToCreate | Foreach-Object {
            New-item "$mainPath/$_" -itemtype directory

            Foreach($subFolders in $subFoldersToCreate) {
                If($null -ne $subFolders.$_) { 
                    $subFolder = $subFolders.$_
                    $Path = "$mainPath/$_/$subFolder"
                    
                    New-item "$Path" -itemtype directory
                }
            }
        }
    }
}

Function Start-Installation {
    If(!$isWindows) {
        $installDir = Invoke-Initialization
        Write-Host "App have been install in $installDir" -ForegroundColor Green
        Add-FolderStructure $installDir
        Read-Host "Press enter to exit"
    } Else {
        Write-Warning "System is not a Windows OS"
        Break;
    }
}

Start-Installation