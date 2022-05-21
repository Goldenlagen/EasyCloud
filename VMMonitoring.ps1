
 Function Watch-VMPerformance {
    $User = 'Administrateur'
    $Password = 'Password'

    $SecurePswd = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePswd

    Invoke-Command -VMId d7a37e58-8487-4128-af60-603535693ce9 -Credential $Credential -ScriptBlock {
        $CompObject =  Get-WmiObject -Class WIN32_OperatingSystem
        $Processor = Get-WmiObject Win32_Processor | Select LoadPercentage
        $Memory = ((($CompObject.TotalVisibleMemorySize - $CompObject.FreePhysicalMemory)*100)/ $CompObject.TotalVisibleMemorySize)

        $VMDetail = @{
            Name = $CompObject.PSComputerName
            Memory = $Memory
            Processor = $Processor.LoadPercentage
        }
    
        Return ($VMDetail | ConvertTo-Json -Depth 2)
    }
}

Watch-VMPerformance
