#!/bin/bash
# SCRIPT DE GESTION DES DROITS D'ACCES - VERSION SIMPLIFIEE

# CONFIGURATION DE BASE
DOSSIER_PROJETS="/home/debian/projects"
FICHIER_UTILISATEURS="/home/debian/users_roles.txt"
DOSSIER_LOGS="/home/debian/logs"

# Nom du fichier log avec date et heure
DATE_HEURE=$(date +"%Y%m%d_%H%M%S")
FICHIER_LOG="$DOSSIER_LOGS/log_$DATE_HEURE.txt"

# FONCTION POUR ECRIRE DANS LE LOG
ecrire_log() {
    message="$1"
    # Afficher a l'ecran
    echo "$message"
    # Ecrire dans le fichier
    echo "$message" >> "$FICHIER_LOG"
}

# FONCTION POUR TROUVER LE ROLE LE PLUS ELEVE
# Ordre : ADMIN (4) > MANAGER (3) > ANALYST (2) > DEV (1)
trouver_role_effectif() {
    roles="$1"
    
    meilleur_role="DEV"
    meilleur_niveau=0
    
    # Separer les roles par virgule
    IFS=',' read -ra liste_roles <<< "$roles"
    
    for role in "${liste_roles[@]}"; do
        # Nettoyer et mettre en majuscules
        role=$(echo "$role" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
        
        # Determiner le niveau
        niveau=0
        case "$role" in
            "DEV")     niveau=1 ;;
            "ANALYST") niveau=2 ;;
            "MANAGER") niveau=3 ;;
            "ADMIN")   niveau=4 ;;
        esac
        
        # Garder le plus eleve
        if [ $niveau -gt $meilleur_niveau ]; then
            meilleur_niveau=$niveau
            meilleur_role=$role
        fi
    done
    
    echo "$meilleur_role"
}

# FONCTION POUR CALCULER LES DROITS
# Arguments: $1 = role, $2 = statut du projet
# Resultat: affiche les droits pour data, results, admin
calculer_droits() {
    role="$1"
    statut="$2"
    
    # Par defaut : aucun acces
    droit_data="AUCUN"
    droit_results="AUCUN"
    droit_admin="AUCUN"
    
    # Si le projet est ACTIF
    if [ "$statut" = "ACTIVE" ]; then
        case "$role" in
            "DEV")
                droit_data="LECTURE_ECRITURE"
                ;;
            "ANALYST")
                droit_data="LECTURE"
                droit_results="LECTURE_ECRITURE"
                ;;
            "MANAGER")
                droit_data="LECTURE"
                droit_results="LECTURE"
                ;;
            "ADMIN")
                droit_data="COMPLET"
                droit_results="COMPLET"
                droit_admin="COMPLET"
                ;;
        esac
    
    # Si le projet est FERME
    elif [ "$statut" = "CLOSED" ]; then
        case "$role" in
            "DEV")
                # Aucun acces
                ;;
            "ANALYST")
                # Aucun acces
                ;;
            "MANAGER")
                droit_results="LECTURE"
                ;;
            "ADMIN")
                droit_data="COMPLET"
                droit_results="COMPLET"
                droit_admin="COMPLET"
                ;;
        esac
    fi
    
    # Retourner les 3 droits separes par des espaces
    echo "$droit_data $droit_results $droit_admin"
}

# DEBUT DU SCRIPT PRINCIPAL
# Creer le dossier logs s'il n'existe pas
mkdir -p "$DOSSIER_LOGS"

# Afficher l'en-tete
ecrire_log "   GESTION DES DROITS D'ACCES"
ecrire_log "   Date : $(date '+%d/%m/%Y %H:%M:%S')"
ecrire_log "   Mode : SIMULATION"
ecrire_log ""

# ETAPE 1 : Verifier le fichier utilisateurs
ecrire_log "LECTURE DES UTILISATEURS"

if [ ! -f "$FICHIER_UTILISATEURS" ]; then
    ecrire_log "ERREUR : Fichier $FICHIER_UTILISATEURS introuvable !"
    exit 1
fi

# Lire et afficher les utilisateurs
while IFS= read -r ligne || [ -n "$ligne" ]; do
    # Ignorer les lignes vides
    [ -z "$ligne" ] && continue
    
    # Nettoyer la ligne (enlever les retours chariot Windows)
    ligne=$(echo "$ligne" | tr -d '\r')
    
    # Separer nom:roles
    nom_utilisateur=$(echo "$ligne" | cut -d':' -f1)
    roles=$(echo "$ligne" | cut -d':' -f2)
    
    ecrire_log "  Utilisateur: $nom_utilisateur - Roles: $roles"
    
done < "$FICHIER_UTILISATEURS"

ecrire_log ""

# ETAPE 2 : Parcourir les projets
ecrire_log "TRAITEMENT DES PROJETS"

# Pour chaque dossier dans /projects
for dossier_projet in "$DOSSIER_PROJETS"/*/; do
    # Extraire le nom du projet
    nom_projet=$(basename "$dossier_projet")
    
    ecrire_log ""
    ecrire_log "PROJET : $nom_projet"
    
    # Lire le statut du projet
    fichier_statut="$dossier_projet/project_status.txt"
    
    if [ ! -f "$fichier_statut" ]; then
        ecrire_log "  ATTENTION : Pas de fichier project_status.txt"
        continue
    fi
    
    # Lire la premiere ligne et nettoyer
    statut=$(head -n 1 "$fichier_statut" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    ecrire_log "  Statut : $statut"
    
        # ETAPE 3 : Traiter chaque utilisateur
        while IFS= read -r ligne || [ -n "$ligne" ]; do
        # Ignorer les lignes vides
        [ -z "$ligne" ] && continue
        
        # Nettoyer la ligne
        ligne=$(echo "$ligne" | tr -d '\r')
        
        # Separer nom:roles
        nom_utilisateur=$(echo "$ligne" | cut -d':' -f1)
        roles=$(echo "$ligne" | cut -d':' -f2)
        
        # Trouver le role effectif
        role_effectif=$(trouver_role_effectif "$roles")
        
        # Calculer les droits
        resultat=$(calculer_droits "$role_effectif" "$statut")
        droit_data=$(echo "$resultat" | cut -d' ' -f1)
        droit_results=$(echo "$resultat" | cut -d' ' -f2)
        droit_admin=$(echo "$resultat" | cut -d' ' -f3)
        
        # Afficher les resultats
        ecrire_log ""
        ecrire_log "  Utilisateur : $nom_utilisateur"
        ecrire_log "  Role effectif : $role_effectif"
        ecrire_log "  Droits simules :"
        ecrire_log "    - data/    : $droit_data"
        ecrire_log "    - results/ : $droit_results"
        ecrire_log "    - admin/   : $droit_admin"
        
    done < "$FICHIER_UTILISATEURS"
done

# FIN DU SCRIPT
ecrire_log ""
ecrire_log "FIN DU TRAITEMENT"
ecrire_log "Log sauvegarde dans : $FICHIER_LOG"