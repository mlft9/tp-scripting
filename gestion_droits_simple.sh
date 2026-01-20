#!/bin/bash
# configuration
DOSSIER_PROJETS="/home/debian/projects"
FICHIER_UTILISATEURS="/home/debian/users_roles.txt"
DOSSIER_LOGS="/home/debian/logs"

# nom fichier log avec date et heure
DATE_HEURE=$(date +"%Y%m%d_%H%M%S")
FICHIER_LOG="$DOSSIER_LOGS/log_$DATE_HEURE.txt"

# fonction ecrire log
ecrire_log() {
    message="$1"
    # afficher a l'ecran
    echo "$message"
    # ecrire dans le fichier
    echo "$message" >> "$FICHIER_LOG"
}

# fonction trouver role effectif
# ordre : admin > manager > analyst > dev
trouver_role_effectif() {
    roles="$1"
    
    meilleur_role="DEV"
    meilleur_niveau=0
    
    # separer roles par virgule
    IFS=',' read -ra liste_roles <<< "$roles"
    
    for role in "${liste_roles[@]}"; do
        # nettoyer et mettre en majuscules
        role=$(echo "$role" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
        
        # determiner niveau
        niveau=0
        case "$role" in
            "DEV")     niveau=1 ;;
            "ANALYST") niveau=2 ;;
            "MANAGER") niveau=3 ;;
            "ADMIN")   niveau=4 ;;
        esac
        
        # garder le plus eleve
        if [ $niveau -gt $meilleur_niveau ]; then
            meilleur_niveau=$niveau
            meilleur_role=$role
        fi
    done
    
    echo "$meilleur_role"
}

# fonction calculer droits
# arguments : $1 = role, $2 = statut du projet
# resultat : affiche les droits pour data, results, admin
calculer_droits() {
    role="$1"
    statut="$2"
    
    # par defaut : aucun acces
    droit_data="AUCUN"
    droit_results="AUCUN"
    droit_admin="AUCUN"
    
    # si le projet est actif
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
    
    # si le projet est ferme
    elif [ "$statut" = "CLOSED" ]; then
        case "$role" in
            "DEV")
                # aucun acces
                ;;
            "ANALYST")
                # aucun acces
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
    
    # retourner les 3 droits separes par des espaces
    echo "$droit_data $droit_results $droit_admin"
}

# debut
# creer dossier logs
mkdir -p "$DOSSIER_LOGS"

# Afficher l'en-tete
ecrire_log "   GESTION DES DROITS D'ACCES"
ecrire_log "   Date : $(date '+%d/%m/%Y %H:%M:%S')"
ecrire_log "   Mode : SIMULATION"
ecrire_log ""

# etape 1 verifier fichier utilisateurs
ecrire_log "LECTURE DES UTILISATEURS"

if [ ! -f "$FICHIER_UTILISATEURS" ]; then
    ecrire_log "ERREUR : Fichier $FICHIER_UTILISATEURS introuvable !"
    exit 1
fi

# lire et afficher les utilisateurs
while IFS= read -r ligne || [ -n "$ligne" ]; do
    # ignorer les lignes vides
    [ -z "$ligne" ] && continue
    
    # nettoyer la ligne
    ligne=$(echo "$ligne" | tr -d '\r')
    
    # separer nom:roles
    nom_utilisateur=$(echo "$ligne" | cut -d':' -f1)
    roles=$(echo "$ligne" | cut -d':' -f2)
    
    ecrire_log "  Utilisateur: $nom_utilisateur - Roles: $roles"
    
done < "$FICHIER_UTILISATEURS"

ecrire_log ""

# etape 2 parcourir projets
ecrire_log "TRAITEMENT DES PROJETS"

# pour chaque dossier dans /projects
for dossier_projet in "$DOSSIER_PROJETS"/*/; do
    # extraire nom du projet
    nom_projet=$(basename "$dossier_projet")
    
    ecrire_log ""
    ecrire_log "PROJET : $nom_projet"
    
    # lire statut du projet
    fichier_statut="$dossier_projet/project_status.txt"
    
    if [ ! -f "$fichier_statut" ]; then
        ecrire_log "  ATTENTION : Pas de fichier project_status.txt"
        continue
    fi
    
    # lire premiere ligne et nettoyer
    statut=$(head -n 1 "$fichier_statut" | tr -d '\r' | tr '[:lower:]' '[:upper:]')
    ecrire_log "  Statut : $statut"
    
    # etape 3 : traiter chaque utilisateur
    while IFS= read -r ligne || [ -n "$ligne" ]; do
        # ignorer lignes vides
        [ -z "$ligne" ] && continue
        
        # nettoyer la ligne
        ligne=$(echo "$ligne" | tr -d '\r')
        
        # separer nom:roles
        nom_utilisateur=$(echo "$ligne" | cut -d':' -f1)
        roles=$(echo "$ligne" | cut -d':' -f2)
        
        # trouver role effectif
        role_effectif=$(trouver_role_effectif "$roles")
        
        # calculer droits
        resultat=$(calculer_droits "$role_effectif" "$statut")
        droit_data=$(echo "$resultat" | cut -d' ' -f1)
        droit_results=$(echo "$resultat" | cut -d' ' -f2)
        droit_admin=$(echo "$resultat" | cut -d' ' -f3)
        
        # afficher resultats
        ecrire_log ""
        ecrire_log "  Utilisateur : $nom_utilisateur"
        ecrire_log "  Role effectif : $role_effectif"
        ecrire_log "  Droits simules :"
        ecrire_log "    - data/    : $droit_data"
        ecrire_log "    - results/ : $droit_results"
        ecrire_log "    - admin/   : $droit_admin"
        
    done < "$FICHIER_UTILISATEURS"
done

# fin 
ecrire_log ""
ecrire_log "FIN DU TRAITEMENT"
ecrire_log "Log sauvegarde dans : $FICHIER_LOG"