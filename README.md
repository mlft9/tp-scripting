# TP6 - Gestion Automatisée des Droits d'Accès

Script de gestion des droits d'accès aux projets selon les rôles des utilisateurs.

## Structure du projet

```
TP6_Access_Rights/
├── gestion_droits_simple.sh   # Script principal (Bash)
├── users_roles.txt            # Liste des utilisateurs et rôles
├── projects/                  # Dossier des projets
│   ├── ProjectA/
│   │   ├── data/
│   │   ├── results/
│   │   ├── admin/
│   │   └── project_status.txt
│   ├── ProjectB/
│   └── ProjectC/
├── logs/                      # Fichiers de log générés
├── COMPTE_RENDU_TP6.md        # Compte rendu du TP
└── README.md
```

## Utilisation

### Exécuter le script Bash

```bash
chmod +x gestion_droits_simple.sh
./gestion_droits_simple.sh
```

## Configuration

### Fichier `users_roles.txt`

Format : `nom:role1,role2,...`

```
mathis:DEV
ridwan:ANALYST
hugo:MANAGER
seb:ADMIN
```

### Fichier `project_status.txt`

Chaque projet doit contenir un fichier avec le statut : `ACTIVE` ou `CLOSED`

## Rôles et droits

**Hiérarchie :** ADMIN > MANAGER > ANALYST > DEV

| Rôle    | Projet ACTIVE                      | Projet CLOSED    |
| ------- | ---------------------------------- | ---------------- |
| DEV     | data: lecture/écriture             | Aucun accès      |
| ANALYST | data: lecture, results: lect/écrit | Aucun accès      |
| MANAGER | data: lecture, results: lecture    | results: lecture |
| ADMIN   | Accès complet à tous les dossiers  | Accès complet    |

## Logs

Les logs sont générés dans `logs/` avec le format : `log_YYYYMMDD_HHMMSS.txt`
