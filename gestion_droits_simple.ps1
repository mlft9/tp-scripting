# conf - chemins relatifs au script
$PROJETS = Join-Path $PSScriptRoot "projects"
$USERS = Join-Path $PSScriptRoot "users_roles.txt"
$LOGS_DIR = Join-Path $PSScriptRoot "logs"
$LOG = Join-Path $LOGS_DIR "log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# creer dossier logs
New-Item -ItemType Directory -Force -Path $LOGS_DIR | Out-Null

# fonction ecrire log
function Log {
    param([string]$Message)
    $Message | Tee-Object -FilePath $LOG -Append
}

# fonction role le plus eleve
function Get-RoleMax {
    param([string]$Roles)
    $max = "DEV"
    if ($Roles -match "ANALYST") { $max = "ANALYST" }
    if ($Roles -match "MANAGER") { $max = "MANAGER" }
    if ($Roles -match "ADMIN")   { $max = "ADMIN" }
    return $max
}

# fonction calculer droits
function Get-Droits {
    param([string]$Role, [string]$Statut)
    # d=data, r=resultats, a=admin
    $d = "AUCUN"; $r = "AUCUN"; $a = "AUCUN"
    
    if ($Statut -eq "ACTIVE") {
        switch ($Role) {
            "DEV"     { $d = "LECTURE_ECRITURE" }
            "ANALYST" { $d = "LECTURE"; $r = "LECTURE_ECRITURE" }
            "MANAGER" { $d = "LECTURE"; $r = "LECTURE" }
            "ADMIN"   { $d = "COMPLET"; $r = "COMPLET"; $a = "COMPLET" }
        }
    } else {  # CLOSED
        switch ($Role) {
            "MANAGER" { $r = "LECTURE" }
            "ADMIN"   { $d = "COMPLET"; $r = "COMPLET"; $a = "COMPLET" }
        }
    }
    return @{ Data = $d; Results = $r; Admin = $a }
}

# programme principal
Log "GESTION DROITS - $(Get-Date)"

# verifier fichier utilisateurs
if (-not (Test-Path $USERS)) {
    Log "ERREUR: $USERS introuvable"
    exit 1
}

# parcourir chaque projet
Get-ChildItem -Path $PROJETS -Directory | ForEach-Object {
    $nom = $_.Name
    $statusFile = Join-Path $_.FullName "project_status.txt"
    
    if (Test-Path $statusFile) {
        $statut = (Get-Content $statusFile -First 1).Trim().ToUpper()
    } else {
        return  # continue dans foreach
    }
    
    # si vide
    if ([string]::IsNullOrEmpty($statut)) { return }
    
    Log ""
    Log "PROJET: $nom ($statut)"
    
    # pour chaque utilisateur
    Get-Content $USERS | ForEach-Object {
        $line = $_.Trim()
        if ([string]::IsNullOrEmpty($line)) { return }
        
        $parts = $line -split ":"
        $user = $parts[0].Trim()
        $roles = if ($parts.Length -gt 1) { $parts[1].Trim().ToUpper() } else { "" }
        
        # ignore vide
        if ([string]::IsNullOrEmpty($user)) { return }
        
        $role = Get-RoleMax -Roles $roles
        $droits = Get-Droits -Role $role -Statut $statut
        
        Log "  $user [$role] -> data:$($droits.Data) results:$($droits.Results) admin:$($droits.Admin)"
    }
}

Log ""
Log "FIN"