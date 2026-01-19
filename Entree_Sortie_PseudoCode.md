# Compte Rendu - TP6 : Gestion Automatisée des Droits d'Accès

**Auteur :** Maxime, Antoine et JM
**Date :** 19 janvier 2026

---

## 1. Entrées

| Fichier                             | Contenu                               |
| ----------------------------------- | ------------------------------------- |
| `users_roles.txt`                   | Liste des utilisateurs et leurs rôles |
| `projects/<nom>/project_status.txt` | État du projet : ACTIVE ou CLOSED     |


**Hiérarchie des rôles :**

```
ADMIN (4) > MANAGER (3) > ANALYST (2) > DEV (1)
```

---

## 2. Sorties Attendues

### Droits selon le rôle et l'état du projet

**Projet ACTIVE :**
| Rôle | data/ | results/ | admin/ |
|------|-------|----------|--------|
| DEV | Lecture+Écriture | Aucun | Aucun |
| ANALYST | Lecture | Lecture+Écriture | Aucun |
| MANAGER | Lecture | Lecture | Aucun |
| ADMIN | Complet | Complet | Complet |

**Projet CLOSED :**
| Rôle | data/ | results/ | admin/ |
|------|-------|----------|--------|
| DEV | Aucun | Aucun | Aucun |
| ANALYST | Aucun | Aucun | Aucun |
| MANAGER | Aucun | Lecture | Aucun |
| ADMIN | Complet | Complet | Complet |

### Fichier de log

Le script génère un fichier log avec :

- Nom du projet et son statut
- Nom de l'utilisateur et son rôle effectif
- Droits appliqués sur chaque dossier

---

## 3. Pseudo-Code

```
DEBUT

# Configuration
DOSSIER_PROJETS = "./projects"
FICHIER_UTILISATEURS = "./users_roles.txt"
DOSSIER_LOGS = "./logs"

# Creer dossier logs si besoin
Creer dossier DOSSIER_LOGS

# Afficher en-tete
Ecrire "GESTION DES DROITS D'ACCES"
Ecrire "Date : " + date actuelle
Ecrire "Mode : SIMULATION"

# ETAPE 1 : Lire les utilisateurs
Ecrire "LECTURE DES UTILISATEURS"

Si FICHIER_UTILISATEURS n'existe pas:
    Ecrire "ERREUR : Fichier introuvable"
    Quitter

Pour chaque ligne dans FICHIER_UTILISATEURS:
    Si ligne vide: continuer
    nom = partie avant ":"
    roles = partie apres ":"
    Ecrire "Utilisateur: " + nom + " - Roles: " + roles
Fin Pour

# ETAPE 2 : Parcourir les projets
Ecrire "TRAITEMENT DES PROJETS"

Pour chaque dossier dans DOSSIER_PROJETS:
    nom_projet = nom du dossier
    Ecrire "PROJET : " + nom_projet

    # Lire le statut
    Si project_status.txt n'existe pas:
        Ecrire "ATTENTION : Pas de fichier project_status.txt"
        Continuer au projet suivant
    Fin Si

    statut = lire premiere ligne de project_status.txt
    Ecrire "Statut : " + statut

    # ETAPE 3 : Traiter chaque utilisateur
    Pour chaque ligne dans FICHIER_UTILISATEURS:
        nom = partie avant ":"
        roles = partie apres ":"

        # Trouver role effectif (le plus eleve)
        meilleur_role = "DEV"
        meilleur_niveau = 0

        Pour chaque role dans roles:
            Si role = "DEV"     alors niveau = 1
            Si role = "ANALYST" alors niveau = 2
            Si role = "MANAGER" alors niveau = 3
            Si role = "ADMIN"   alors niveau = 4

            Si niveau > meilleur_niveau:
                meilleur_niveau = niveau
                meilleur_role = role
            Fin Si
        Fin Pour

        # Calculer les droits
        droit_data = "AUCUN"
        droit_results = "AUCUN"
        droit_admin = "AUCUN"

        Si statut = "ACTIVE":
            Si meilleur_role = "DEV":
                droit_data = "LECTURE_ECRITURE"
            Si meilleur_role = "ANALYST":
                droit_data = "LECTURE"
                droit_results = "LECTURE_ECRITURE"
            Si meilleur_role = "MANAGER":
                droit_data = "LECTURE"
                droit_results = "LECTURE"
            Si meilleur_role = "ADMIN":
                droit_data = "COMPLET"
                droit_results = "COMPLET"
                droit_admin = "COMPLET"
        Fin Si

        Si statut = "CLOSED":
            Si meilleur_role = "DEV":
                (aucun acces)
            Si meilleur_role = "ANALYST":
                (aucun acces)
            Si meilleur_role = "MANAGER":
                droit_results = "LECTURE"
            Si meilleur_role = "ADMIN":
                droit_data = "COMPLET"
                droit_results = "COMPLET"
                droit_admin = "COMPLET"
        Fin Si

        # Afficher resultats
        Ecrire "Utilisateur : " + nom
        Ecrire "Role effectif : " + meilleur_role
        Ecrire "Droits simules :"
        Ecrire "  - data/    : " + droit_data
        Ecrire "  - results/ : " + droit_results
        Ecrire "  - admin/   : " + droit_admin

    Fin Pour
Fin Pour

# Fin
Ecrire "FIN DU TRAITEMENT"
Ecrire "Log sauvegarde dans : " + FICHIER_LOG

FIN
```

---

## 4. Cas d'Erreur et Limites

| Problème                              | Que fait le script                    |
| ------------------------------------- | ------------------------------------- |
| Fichier `users_roles.txt` manquant    | Arrête avec un message d'erreur       |
| Fichier `project_status.txt` manquant | Ignore ce projet, continue les autres |
| Ligne mal formatée                    | Ignore la ligne                       |
| Rôle inconnu                          | L'utilisateur n'a aucun droit         |

### Limites

- Mode **simulation** uniquement (n'applique pas vraiment les droits)
- Ne gère pas les groupes d'utilisateurs
