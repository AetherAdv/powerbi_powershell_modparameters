Connect-PowerBIServiceAccount

# Updates first parameter - parameter 0
$UpdateParameter0 = "MyNewParameterValue"

$workspaces = Get-PowerBIWorkspace -All

foreach ($workspace in $workspaces) {

    # Get reports with names starting with "AETHER" in the current workspace
    $Reportlist = Get-PowerBIReport -WorkspaceId $workspace.Id | Where-Object { $_.Name -like 'AETHER*' }

    if ($Reportlist) {
        Write-Host "Workspace: $($workspace.Name)"

        foreach ($Report in $Reportlist) {
            Write-Host "  Report: $($Report.Name)"

            $JsonString = $null

            $ParametersJsonString = Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.Id)/datasets/$($Report.DatasetId)/parameters" -Method Get
            $Parameters = (ConvertFrom-Json $ParametersJsonString).value

            $UpdateParameterList = @() # Initialize as an empty array

            foreach ($Parameter in $Parameters) {
                $UpdateParameterList += @{ "name" = $Parameter.name; "newValue" = $Parameter.currentValue }
            }

            if ($UpdateParameterList.Count -gt 0) { #check if parameters exist.
                $currentparam = $UpdateParameterList[0].newValue

                Write-Host "    Current Parameter 0 Value: $currentparam"

                if ($currentparam -ne $UpdateParameter0) {
                    Write-Host "Parameter 0 value does not match. Updating..."

                    $UpdateParameterList[0].newValue = $UpdateParameter0
                }
                else{
                    Write-Host "Parameter 0 value already matches. Skipping update."
                }

                $JsonBase = @{ "updateDetails" = $UpdateParameterList }
                $JsonString = $JsonBase | ConvertTo-Json

                # Update the parameters
                Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.Id)/datasets/$($Report.DatasetId)/Default.UpdateParameters" -Method Post -Body $JsonString

                Start-Sleep -Seconds 5

                # Refresh the data
                Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/groups/$($workspace.Id)/datasets/$($Report.DatasetId)/refreshes" -Method Post
                Write-Host "Refresh started."
            }
            else{
                Write-Host "No parameters found for this dataset."
            }
        }
    } else {
      Write-Host "No reports found in workspace: $($workspace.Name)"
    }
}
Write-Host "Script completed."