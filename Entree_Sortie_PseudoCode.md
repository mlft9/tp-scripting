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

# configuration
PROJETS = "/home/debian/projects"
USERS = "/home/debian/users_roles.txt"
LOG = "/home/debian/logs/log_<date>.txt"

Creer dossier logs

# fonction log : affiche ET ecrit dans fichier
FONCTION log(message):
    Afficher message
    Ecrire message dans LOG

# fonction role_max : trouve le role le plus eleve
FONCTION role_max(roles):
    max = "DEV"
    Si roles contient "ANALYST" : max = "ANALYST"
    Si roles contient "MANAGER" : max = "MANAGER"
    Si roles contient "ADMIN"   : max = "ADMIN"
    Retourner max

# fonction droits : calcule les droits selon role et statut
FONCTION droits(role, statut):
    d = "AUCUN", r = "AUCUN", a = "AUCUN"

    Si statut = "ACTIVE":
        Si role = "DEV"     : d = "LECTURE_ECRITURE"
        Si role = "ANALYST" : d = "LECTURE", r = "LECTURE_ECRITURE"
        Si role = "MANAGER" : d = "LECTURE", r = "LECTURE"
        Si role = "ADMIN"   : d = "COMPLET", r = "COMPLET", a = "COMPLET"
    Sinon (CLOSED):
        Si role = "MANAGER" : r = "LECTURE"
        Si role = "ADMIN"   : d = "COMPLET", r = "COMPLET", a = "COMPLET"

    Retourner d, r, a

# programme principal
log("GESTION DROITS - " + date)

Si USERS n'existe pas:
    log("ERREUR: fichier introuvable")
    Quitter

Pour chaque projet dans PROJETS:
    nom = nom du dossier
    statut = lire project_status.txt (en majuscules)
    Si statut vide: passer au suivant

    log("PROJET: " + nom + " (" + statut + ")")

    Pour chaque ligne (user:roles) dans USERS:
        Si user vide: continuer
        role = role_max(roles)
        d, r, a = droits(role, statut)
        log("  " + user + " [" + role + "] -> data:" + d + " results:" + r + " admin:" + a)
    Fin Pour
Fin Pour

log("FIN")

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
