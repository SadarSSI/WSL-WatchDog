Clear-Host
function CheckSecurityLevel {

  # Self-elevate the script if required
  if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {  
      $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " 
      Write-Host "Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine"
      Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
      Exit
    }
  }


}
function LoadParams{
    Write-Host "Load $PSScriptRoot\wsl_params.yml..." -ForegroundColor DarkCyan
    Write-Host (" " * $indent)
    
    $script:Params    = ConvertFrom-Yaml -Yaml (Get-Content -Path "$PSScriptRoot\wsl_params.yml" -Raw)
    
    $script:Killall   = $Params.WSLCommon.KillallBeforeStarting
  
    $script:Distrib   = $Params.WSLCommon.Distro
    $script:StartWSL  = $ExecutionContext.InvokeCommand.ExpandString($Params.WSLCommon.StartWSL)
    $script:StopWSL   = $ExecutionContext.InvokeCommand.ExpandString($Params.WSLCommon.StopWSL)
    $script:GetWSLVer = $Params.WSLCommon.GetWSLVer
    $script:GetWSLIP  = $Params.WSLCommon.GetWSLIP
    $script:SleepTime = $Params.WSLCommon.SleepTime
    
    $script:wsl       = $(get-command wsl.exe).Path
    $script:WSLVer    = $(Invoke-Expression "$wsl $GetWSLVer" ).split(" ")[-3]
    $script:WSLIP     = $(Invoke-Expression "$wsl $GetWSLIP"  ).Replace(' ','')
    
    # Proxy command
    $script:ShowProxyV4ToV4 = $Params.ProxyV4.ShowProxyV4ToV4
    $script:DelProxyV4ToV4  = $Params.ProxyV4.DelProxyV4ToV4
    $script:AddProxyV4ToV4  = $Params.ProxyV4.AddProxyV4ToV4
    $script:SetProxyV4ToV4  = $Params.ProxyV4.SetProxyV4ToV4
  
    # "vEthernet (WSL)" @IP
    $script:vEthAlias   = $Params.WSLCommon.vEthAlias
    $script:vEthIP      = $Params.WSLCommon.vEthIP
    $script:vEthMasq    = $Params.WSLCommon.vEthMasq
    $script:DisableIPV6 = $Params.WSLCommon.DisableIPV6
    
    $script:v4tov4IP        = [regex]::matches($(Invoke-Expression $ShowProxyV4ToV4), "(172\.\d{1,3}\.\d{1,3}\.\d{1,3})").value 
  }
 
function CheckProcess {
  $script:Restarted=$false

  if ($script:Killall -eq $true) {
    $WSLProcess = Get-Process -Name wsl*; Stop-Process -InputObject $WSLProcess; Get-Process | Where-Object {$_.HasExited}
  }

  if((get-process "wsl" -ea SilentlyContinue) -eq $Null)
  { 
    Clear-Host

    Write-Host (" " * $indent) "wsl not running" -ForegroundColor Yellow -BackgroundColor Red
    Write-Host (" " * $indent) "Invoke-Expression $wsl $StopWSL" -ForegroundColor Yellow
    Invoke-Expression "$wsl $StopWSL " -Verbose

    Write-Host (" " * $indent) "Start-Process -FilePath $wsl -ArgumentList $StartWSL" -ForegroundColor Yellow
    Start-Process -FilePath $wsl -ArgumentList $StartWSL -WindowStyle Hidden 
    $script:Restarted=$True
    Write-Host (" " * $indent)
  }

  $script:State="Running"

}
function CheckFirewallRules {

  foreach ( $script:Port in $Params.Ports.Keys) {

    Write-Host (" " * $indent) "FireWallRules" -ForegroundColor Gray
    $script:Protocol    = $($ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port]."Protocol"))
    $script:RuleName    = $($ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port]."RuleDescipt"))
    $script:RuleProfile = $($ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port]."RuleProfile"))
    $FWRule             = Get-NetFirewallRule -DisplayName $RuleName -ea SilentlyContinue
    $FWPort             = $FWRule | Get-NetFirewallPortFilter 
    
    Write-Host (" " * $indent) 

    if ( ($FWRule.Enabled -eq $True) -and ($FWRule.Profile -eq $RuleProfile) -and ($FWRule.Action -eq "Allow") -and ($FWRule.Direction -eq "Inbound") -and
         ($FWPort.LocalPort -eq $Port) -and ($FWPort.Protocol -eq $Protocol) -and ($FWPort.Protocol -eq $Protocol) )
        { 

          Write-Color -Text "   FireWall Rule OK : RuleName:", "$RuleName", ", RuleProfile:","$RuleProfile",", Protocol:", "$Protocol", ", Port:", "$Port"  `
            -color Gray,Yellow,Gray,Yellow,Gray,Yellow,Gray,Yellow

        } else {
          Write-Color -Text "   Need to recreate FireWall Rule : RuleName:", "$RuleName", ", RuleProfile:","$RuleProfile",", Protocol:", "$Protocol", ", Port:", "$Port"  `
            -color Gray,Green,Gray,Green,Gray,Green,Gray,Green

          Write-Host (" " * $indent) 
          Write-Host (" " * $indent)( " " * 1 ) "$($ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port]."DelFirewallRule")) " -ForegroundColor Red -NoNewline
          Invoke-Expression $($ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port]."DelFirewallRule")) | out-null
          Write-Host "Delete rule OK " | Out-String -NoNewline | out-null          

          Write-Host (" " * $indent)( " " * 1 ) "$($ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port]."AddFirewallRule")) " -ForegroundColor Green -NoNewline
          Invoke-Expression $($ExecutionContext.InvokeCommand.ExpandString($Params.Ports[$Port]."AddFirewallRule")) -Verbose

        }
  }

}
function CheckProxyV4 {

  Write-Host (" " * $indent) 
  Write-Host (" " * $indent) "ProxyV4" -ForegroundColor Gray
  # Write-Host (" " * $indent) "vEthIP:$vEthIP., $($vEthIP.Substring(0, 3))" -ForegroundColor Yellow

  $v4tov4IP   = [regex]::matches($(Invoke-Expression $ShowProxyV4ToV4), "("+$($vEthIP.Substring(0, 3))+"\.\d{1,3}\.\d{1,3}\.\d{1,3})").value
  $v4tov4Port = [regex]::matches($(Invoke-Expression "netsh interface portproxy show v4tov4"), "($Port)").value[0]
  $WSLIP      = (Invoke-Expression "$wsl $GetWSLIP"  ).trim()

  Write-Host (" " * $indent) 
  # Write-Host (" " * $indent)( " " * "1" ) "v4tov4IP:$v4tov4IP, v4tov4Port:$v4tov4Port" -ForegroundColor Yellow
  # Write-Host (" " * $indent)( " " * "1" ) "$(Invoke-Expression $ShowProxyV4ToV4)" -ForegroundColor Yellow
  

  if ( ($WSLIP -ne $v4tov4IP) -or ($Port -ne $v4tov4Port) ) {
    # Delete Rule
    Write-Host (" " * $indent)( " " * 1 )  "$DelProxyv4Tov4  "  -ForegroundColor Red -NoNewline
    Invoke-Expression $DelProxyv4Tov4 -verbose
    
    # Create Rule
    Write-Host (" " * $indent)( " " * 1 )  "$AddProxyV4ToV4" -ForegroundColor Green -NoNewline
    Invoke-Expression -Command $AddProxyV4ToV4 -Verbose #| out-null

    $script:v4tov4IP   = [regex]::matches($(Invoke-Expression $ShowProxyV4ToV4), "("+$($vEthIP.Substring(0, 3))+"\.\d{1,3}\.\d{1,3}\.\d{1,3})").value
    $script:WSLIP      = (Invoke-Expression "$wsl $GetWSLIP"  ).trim()

    }else{
      Write-Color -Text "   ProxyV4 OK : v4tov4IP:","$v4tov4IP", ", WSLIP:", "$WSLIP", ", v4tov4Port:", "$v4tov4Port"  -color Gray,Yellow,Gray,Yellow,Gray,Yellow
    }
  
  Write-Host (" " * $indent) 
}
function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
  for ($i = 0; $i -lt $Text.Length; $i++) {
      Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
  }
  Write-Host
}

# Self-elevate the script if required
CheckSecurityLevel

LoadParams
CheckProcess
CheckFirewallRules
CheckProxyV4
  
Write-Color -Text "Distrib:","$Distrib",", version:","$WSLVer",", Restarted:","$Restarted",", state:","$State",", WSLIP:", "$WSLIP", ", ProxyV4:","$v4tov4IP"  `
            -color Gray,Yellow,Yellow,Yellow,Gray,Yellow,Gray,Yellow,Gray,Green,Gray,Green 

Write-Host (" " * $indent)
