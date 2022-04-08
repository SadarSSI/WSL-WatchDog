function LoadParams{
  Write-Host "Load $PSScriptRoot\wsl_params.yml..." -ForegroundColor DarkCyan
  Write-Host (" " * $indent)
  
  $script:Params    = ConvertFrom-Yaml -Ordered -Yaml (Get-Content -Path "$PSScriptRoot\wsl_params.yml" -Raw)  

}

function ReadTask {

  Write-Host (" " * $indent) "ReadTask" -ForegroundColor Gray
  $script:User              = $ExecutionContext.InvokeCommand.ExpandString($Params.Task.User)
  $script:TaskName          = $($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskName))
  $script:ExecName          = $($ExecutionContext.InvokeCommand.ExpandString($Params.Task.ExecName))
  $script:WorkDir           = $($ExecutionContext.InvokeCommand.ExpandString($Params.Task.WorkDir))
  $script:PowerShell        = $($ExecutionContext.InvokeCommand.ExpandString($Params.Task.PowerShell))
  $script:unRegister        = $($ExecutionContext.InvokeCommand.ExpandString($Params.Task.unRegister))
  $script:TaskUserPrincipal = Invoke-Expression "$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskUserPrincipal))"
  $script:TaskAction        = Invoke-Expression "$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskAction))"

}
function CreatTask {

  Write-Host (" " * $indent) "CreatTask" -ForegroundColor Gray
  Write-Host "$($nl)"
  Write-Host "  - Remove Task $($Params.Task.TaskName)" -ForegroundColor Red
  Write-Host "  - $unRegister" -ForegroundColor Red
  Write-Host "$($nl)"
  Invoke-Expression $unRegister

  Invoke-Expression "$unRegister"

  foreach ( $script:Task in $Params.Task.TasksTrigger.Keys) {
    $CurrentTask = $Params.Task.TasksTrigger[$Task]

    # Write-Host (" " * $indent) "Task.TaskType : $Task.TaskType" -ForegroundColor Gray
    if ($CurrentTask.TaskType -eq "Auto"){
      Write-Host (" " * $indent) "TasksTrigger : $Task" -ForegroundColor Gray
      $TaskTrigger     = Invoke-Expression "$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TasksTrigger[$Task]."Task"))"
      $TaskSettings    = Invoke-Expression "$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TasksTrigger[$Task]."TaskSettings"))"

      $Register= $Params.Task.Register
      $Register= $Register.Replace('$TaskName',$TaskName)
      $Register= $Register.Replace('$TaskAction',$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskAction)))
      $Register= $Register.Replace('$TaskUserPrincipal',$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TaskUserPrincipal)))
      $Register= $Register.Replace('$TaskTrigger',$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TasksTrigger[$Task]."Task")))
      $Register= $Register.Replace('$TaskSettings',$($ExecutionContext.InvokeCommand.ExpandString($Params.Task.TasksTrigger[$Task]."TaskSettings")))
      
      Write-Host "`n"$Register  -ForegroundColor Yellow 
      Invoke-Expression "$($Params.Task.Register)" | out-null

    }else{

      $Triggers  = @()
      $TaskIntervall =  $Params.Task.TasksTrigger[$Task]."TaskIntervall"
      $TaskDuration  = $Params.Task.TasksTrigger[$Task]."TaskDuration"

      Write-Host (" " * $indent)
      Write-Host (" " * $indent) "TasksTrigger : $Task, $TaskName" -ForegroundColor Gray
      Write-Host (" " * $indent)
      Write-Host (" " * $indent) "P(eriod) D(ays) T(ime) H(ours) M(inutes) S(econds)" -ForegroundColor Gray
      Write-Host (" " * $indent) "P0DT0H5M0S P0 days, T0 hours, 5 minutes, 0 seconds" -ForegroundColor Gray
      Write-Host (" " * $indent) $TaskIntervall ": TaskIntervall "  -ForegroundColor Yellow
      Write-Host (" " * $indent) $TaskDuration ": TaskDuration  "  -ForegroundColor Yellow

      $Task00 = $Params.Task.TasksTrigger[$Task]."Task00"
      $Task00 = $Task00.Replace('$TaskName',$TaskName)
      Write-Host (" " * $indent) "Task00 " -ForegroundColor Gray
      Write-Host (" " * $indent) $Task00 -ForegroundColor Yellow

      $Task01 = $Params.Task.TasksTrigger[$Task]."Task01"
      $Task01 = $Task01.Replace('$TaskName',$TaskName)
      $Task01 = $($Task01).Replace('$TaskIntervall',$TaskIntervall)
      $Task01 = $($Task01).Replace('$TaskDuration',$TaskDuration)
      Write-Host (" " * $indent) "Task01 " -ForegroundColor Gray
      Write-Host (" " * $indent) $Task01 -ForegroundColor Yellow

      Invoke-Expression "$($Params.Task.TasksTrigger[$Task]."Task00")" | out-null
      Invoke-Expression "$($Params.Task.TasksTrigger[$Task]."Task01")" | out-null
    }
  }
  
}

Clear-Host

LoadParams
ReadTask
CreatTask