#this is support class
Class SqlResult
{
    [int]$NotChanged
    [int]$Changed
    [int]$Added
    [int]$Error
    [string]$result
}


<#
.Synopsis
   Enables pipeline processing of data
.DESCRIPTION
  Enables pipeline processing of data
  Add upsert query with parameters exactly like pipeline input
  Output object provides execution informaiton
  Uses simplysql sql module
.EXAMPLE
   Example of how to use this cmdlet
$sqlStatusupsert=@"
INSERT INTO laststatuschange (DeviceID, StatusChanged, isCompliant) VALUES
	(@DeviceID, @StatusChanged, @isCompliant)
ON DUPLICATE KEY UPDATE
 StatusChanged=@StatusChanged, isCompliant=@isCompliant;
"@
$resadded=$edrwcompliance | DeviceID,
                            @{n='StatusChanged';e={$curdate}}, 
                            @{n='isCompliant';e={if($_.Compliance -eq 'Compliant'){1}else{0}}}|
                           Invoke-SqlUpdateGroup -query $sqlStatusupsert
"`r`nStatus added {0}" -f $resadded.result
#>
function Invoke-SqlUpdateGroup
{
    [CmdletBinding()]
    [OutputType([SqlResult])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [Object]$Parameters,

        # Param2 help description
        [string]
        $query
    )

    Begin
    {
    $result = new-object SqlResult
    }
    Process
    {
    $ht = @{}
    $Parameters.psobject.properties | Foreach { $ht[$_.Name] = $_.Value }
     $sqlres=Invoke-SqlUpdate -Query $query -Parameters $ht
      switch ($sqlres)
     {
         0 {$result.NotChanged++}
         1 {$result.Added++}
         2 {$result.Changed++}
         Default {$result.Error++;$sqlres}
     }
    }
    End
    {
    $result.result="Added:{0} Changed:{1} same:{2} error:{3}" -f $result.Added,$result.Changed,$result.NotChanged,$result.Error
    return $result
    }
}
