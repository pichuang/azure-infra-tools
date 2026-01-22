<#
.SYNOPSIS
  取得指定 tenant 的 Enterprise Application 擁有者與指派資訊。

.DESCRIPTION
  逐一查詢 tenant 內所有 Enterprise Application（service principals），
  輸出 Owners 與 App Role 指派（使用者/群組/服務主體）資訊。
  僅輸出「有 Owners 或有指派」的項目。

.PARAMETER TenantId
  目標 tenant 的 ID（GUID）。

.EXAMPLE
  ./get_permission.ps1 -TenantId "60c041af-d3e5-4152-a034-e8e449c34ab4"

.NOTES
  需要管理員同意的委派權限：
  - Application.Read.All
  - Directory.Read.All
  - AppRoleAssignment.ReadWrite.All
  - User.Read.All
  - Group.Read.All
  - RoleManagement.Read.Directory
  輸出檔案：enterprise-app-assignments.csv
#>
param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[0-9a-fA-F-]{36}$')]
  [string]$TenantId
)

# 1) 連線到指定 tenant（委派權限）
Connect-MgGraph -TenantId $TenantId `
  -Scopes "Application.Read.All","Directory.Read.All","AppRoleAssignment.ReadWrite.All","User.Read.All","Group.Read.All","RoleManagement.Read.Directory"

# 2) 取全部 Enterprise Application (service principals)
$apps = Get-MgServicePrincipal -All -Property Id,DisplayName,AppId
$total = $apps.Count
$index = 0
$rowId = 0

# 3) 逐一取 Owners 與 App Role 指派 (users / groups / service principals)
$result = foreach ($sp in $apps) {
  $index++
  Write-Progress -Activity "取得 Enterprise Application 權限" -Status ("{0}/{1} - {2}" -f $index, $total, $sp.DisplayName) -PercentComplete (($index / $total) * 100)
  # 取得 Owners 與 App Role 指派清單
  $owners = Get-MgServicePrincipalOwner -ServicePrincipalId $sp.Id -All
  $assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -All
  # 清理 Owners 空值，避免誤判
  $ownerIds = @($owners.Id | Where-Object { $_ })
  $hasOwners = $ownerIds.Count -gt 0
  $hasAssignments = $assignments.Count -gt 0
  if ($hasOwners -or $hasAssignments) {
    Write-Host ("Processing App: {0} (AppId: {1}) | Owners: {2} | Assignments: {3}" -f $sp.DisplayName, $sp.AppId, $owners.Count, $assignments.Count)
  }

  # 沒有指派但有 Owners 的情況
  if (-not $assignments) {
    if ($hasOwners) {
      $rowId++
      $row = [pscustomobject]@{
        RowId            = $rowId
        AppDisplayName   = $sp.DisplayName
        AppId            = $sp.AppId
        OwnerIds         = ($ownerIds -join ";")
        PrincipalType    = ""
        PrincipalId      = ""
        PrincipalName    = ""
        AppRoleId        = ""
      }
      Write-Host ('RowId={0} | App="{1}" | AppId={2} | Owners={3} | PrincipalType= | PrincipalId= | PrincipalName="" | AppRoleId=' -f
        $row.RowId, $row.AppDisplayName, $row.AppId, $row.OwnerIds)
      $row
    }
  } else {
    # 有指派的情況（每一筆指派輸出一行）
    foreach ($a in $assignments) {
      $rowId++
      $row = [pscustomobject]@{
        RowId            = $rowId
        AppDisplayName   = $sp.DisplayName
        AppId            = $sp.AppId
        OwnerIds         = ($ownerIds -join ";")
        PrincipalType    = $a.PrincipalType
        PrincipalId      = $a.PrincipalId
        PrincipalName    = $a.PrincipalDisplayName
        AppRoleId        = $a.AppRoleId
      }
      Write-Host ('RowId={0} | App="{1}" | AppId={2} | Owners={3} | PrincipalType={4} | PrincipalId={5} | PrincipalName="{6}" | AppRoleId={7}' -f
        $row.RowId, $row.AppDisplayName, $row.AppId, $row.OwnerIds, $row.PrincipalType, $row.PrincipalId, $row.PrincipalName, $row.AppRoleId)
      $row
    }
  }
}

# 4) 匯出結果（檔名含今日日期 YYYYMMDD）
$dateTag = Get-Date -Format "yyyyMMdd"
$outputPath = ".\enterprise-app-permissions-$dateTag.csv"
$result | Export-Csv $outputPath -NoTypeInformation -Encoding UTF8
Write-Host ("已輸出：{0}" -f $outputPath)
