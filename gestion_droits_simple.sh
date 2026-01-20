#!/bin/bash
# conf - chemins relatifs au script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJETS="$SCRIPT_DIR/projects"
USERS="$SCRIPT_DIR/users_roles.txt"
LOGS_DIR="$SCRIPT_DIR/logs"
LOG="$LOGS_DIR/log_$(date +%Y%m%d_%H%M%S).txt"

# creer dossier logs
mkdir -p "$LOGS_DIR"

# fonction ecrire log
log() {
    echo "$1" | tee -a "$LOG"
}

# fonction role le plus eleve
role_max() {
    local roles="$1" max="DEV"
    [[ "$roles" == *"ANALYST"* ]] && max="ANALYST"
    [[ "$roles" == *"MANAGER"* ]] && max="MANAGER"
    [[ "$roles" == *"ADMIN"* ]]   && max="ADMIN"
    echo "$max"
}

# fonction calculer droits
droits() {
    local role="$1" statut="$2"
    # d=data, r=resultats, a=admin
    local d="AUCUN" r="AUCUN" a="AUCUN"
    
    if [ "$statut" = "ACTIVE" ]; then
        case "$role" in
            DEV)     d="LECTURE_ECRITURE" ;;
            ANALYST) d="LECTURE"; r="LECTURE_ECRITURE" ;;
            MANAGER) d="LECTURE"; r="LECTURE" ;;
            ADMIN)   d="COMPLET"; r="COMPLET"; a="COMPLET" ;;
        esac
    else  # CLOSED
        case "$role" in
            MANAGER) r="LECTURE" ;;
            ADMIN)   d="COMPLET"; r="COMPLET"; a="COMPLET" ;;
        esac
    fi
    echo "$d $r $a"
}

# programme principal
log "GESTION DROITS - $(date)"

# verifier fichier utilisateurs
[ ! -f "$USERS" ] && log "ERREUR: $USERS introuvable" && exit 1

# parcourir chaque projet
for projet in "$PROJETS"/*/; do
    nom=$(basename "$projet")
    statut=$(head -n1 "$projet/project_status.txt" 2>/dev/null | tr -d '\r' | tr a-z A-Z)
    # si vide
    [ -z "$statut" ] && continue
    
    log ""
    log "PROJET: $nom ($statut)"
    
    # pour chaque utilisateur
    while IFS=: read -r user roles; do
        #ignore vide
        [ -z "$user" ] && continue
        roles=$(echo "$roles" | tr -d '\r' | tr a-z A-Z)
        role=$(role_max "$roles")
        # recup valeur droit
        read d r a <<< $(droits "$role" "$statut")
        
        log "  $user [$role] -> data:$d results:$r admin:$a"
    done < "$USERS"
done

log ""
log "FIN"
