function Get-EnvironmentPath {
    [OutputType([string[]], ParameterSetName = 'AsArray')]
    [OutputType([string], ParameterSetName = 'AsString')]
    [CmdletBinding(DefaultParameterSetName = 'AsString')]
    param(
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser',

        [Parameter(ParameterSetName = 'AsArray')]
        [switch] $AsArray
    )

    $separatorChar = [IO.Path]::DirectorySeparatorChar

    $Target = if ($Scope -eq 'CurrentUser') {
        [System.EnvironmentVariableTarget]::User
    } else {
        [System.EnvironmentVariableTarget]::Machine
    }

    $environmentPath = [System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::$Target)
    $environmentPath = $environmentPath | Split-String -Separator ';'
    $environmentPath = $environmentPath | ForEach-Object { $_.Replace('\', $separatorChar).Replace('/', $separatorChar) }
    $environmentPath = $environmentPath | ForEach-Object { $_.TrimEnd($separatorChar) }
    $environmentPath = $environmentPath | Select-Object -Unique | Sort-Object

    if ($AsArray) {
        return $environmentPath
    }

    $environmentPath = $environmentPath -join ';'
    return $environmentPath
}

function Add-EnvironmentPath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser',

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [string[]] $Path
    )

    begin {
        $separatorChar = [IO.Path]::DirectorySeparatorChar

        $Target = if ($Scope -eq 'CurrentUser') {
            [System.EnvironmentVariableTarget]::User
        } else {
            [System.EnvironmentVariableTarget]::Machine
        }
    }

    process {
        foreach ($envPath in $Path) {
            $environmentPath = Get-EnvironmentPath -Scope $Scope -AsArray
            $environmentPath += $Path
            $environmentPath = $environmentPath | ForEach-Object { $_.Replace('\', $separatorChar).Replace('/', $separatorChar) }
            $environmentPath = $environmentPath | ForEach-Object { $_.TrimEnd($separatorChar) }
            $environmentPath = $environmentPath | Select-Object -Unique | Sort-Object
            $environmentPath = $environmentPath -join ';'

            [System.Environment]::SetEnvironmentVariable('PATH', $environmentPath, [System.EnvironmentVariableTarget]::$Target)
        }
    }

    end {}
}

function Remove-EnvironmentPath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string] $Scope = 'CurrentUser'
    )

    DynamicParam {
        $runtimeDefinedParameterDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        # Defining parameter attributes
        $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $attributes = New-Object System.Management.Automation.ParameterAttribute
        $attributes.ParameterSetName = '__AllParameterSets'
        $attributes.Mandatory = $True
        $attributes.ValueFromPipeline = $True
        $attributes.ValueFromPipelineByPropertyName = $True
        $attributeCollection.Add($attributes)

        # Adding ValidateScript parameter validation
        $validateScript = { Get-EnvironmentPath -Scope $Scope -AsArray }
        $validateScriptAttribute = New-Object System.Management.Automation.ValidateScriptAttribute($validateScript)
        $attributeCollection.Add($validateScriptAttribute)

        # Adding a parameter alias
        $dynalias = New-Object System.Management.Automation.AliasAttribute -ArgumentList 'FullName'
        $attributeCollection.Add($dynalias)

        # Defining the runtime parameter
        $dynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter('Path', [string[]], $attributeCollection)
        $runtimeDefinedParameterDictionary.Add('Path', $dynParam1)

        return $runtimeDefinedParameterDictionary
    }

    begin {
        $separatorChar = [IO.Path]::DirectorySeparatorChar
    }

    process {
        if ($Scope -eq 'AllUsers') {
            $environmentPath = ([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::Machine) | Split-String -Separator ';')
            $environmentPath = $environmentPath | Where-Object { $_ -ne $Path }
            $environmentPath = $environmentPath | Select-Object -Unique | Sort-Object
            [System.Environment]::SetEnvironmentVariable('PATH', $environmentPath, [System.EnvironmentVariableTarget]::Machine)
        } else {
            $environmentPath = ([System.Environment]::GetEnvironmentVariable('PATH', [System.EnvironmentVariableTarget]::User) | Split-String -Separator ';')
            $environmentPath += $Path
            $environmentPath = $environmentPath | Select-Object -Unique | Sort-Object
            [System.Environment]::SetEnvironmentVariable('PATH', $environmentPath, [System.EnvironmentVariableTarget]::User)
        }
    }

    end {}
}
