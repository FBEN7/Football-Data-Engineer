# Guide : construire la plateforme data d'un club

Tu reçois le **socle** d'une plateforme comme celle d'un club professionnel :
- la collecte des 3 sources (StatsBomb, Transfermarkt, football-data.co.uk) dans une couche brute en Parquet ;
- un entrepôt DuckDB construit par dbt ;
- l'orchestration Dagster, avec un lancement planifié chaque semaine ;
- la CI GitHub et Docker.

La couche StatsBomb est faite : c'est l'exemple à suivre. **Le reste, c'est toi qui le construis**, jalon par jalon : nettoyer et typer les deux autres sources, les rapprocher (équipes, matchs, joueurs), puis bâtir les tables finales et le rapport de rapprochement.

Saison couverte : **Bayer Leverkusen 2023/24**, soit les 34 matchs de Bundesliga avec StatsBomb, et toute la saison chez Transfermarkt et football-data.

## Comment avancer

1. **Un jalon = un dossier à activer** dans `dbt/dbt_project.yml` (`+enabled: false` → `true`). Tant qu'un dossier est désactivé, dbt, Dagster et la CI l'ignorent.
2. Chaque modèle à écrire existe déjà : c'est une requête vide aux bonnes colonnes, marquée `TODO`. Le fichier `.yml` du dossier donne le contrat : les colonnes, les descriptions et les **tests d'acceptation**.
3. Le jalon est fini quand `python -m cdp dbt build --select <dossier>` passe **sans erreur**.
4. **Une branche et une PR par jalon.** La CI doit être verte avant de fusionner.
5. Écris `docs/notes/Mx.md` (une page) : tes choix, ce que tu as trouvé dans les données, les limites. C'est ce que tu défendras en entretien.

Les tests ne disent pas *comment* faire. Si un test échoue, lis la ligne qu'il renvoie : c'est un indice, pas une punition.

## Mise en route (sur ton PC perso)

1. Installe Python 3.12, Git, et VS Code avec les extensions Python et dbt Power User.
2. Crée un compte Kaggle **personnel**, puis récupère ta clé API : `kaggle.json`, dans `~/.kaggle/` (Windows : `C:\Users\<toi>\.kaggle\`).
3. Lance ces commandes :

```bash
python -m venv .venv
.venv\Scripts\Activate.ps1           # macOS/Linux : source .venv/bin/activate
pip install -e ".[dev]"
python -m cdp ingest                 # environ 1,5 Go de téléchargement, une seule fois
python -m cdp dbt build              # 22 tests verts : la couche StatsBomb
dagster dev -m cdp.definitions       # interface sur http://localhost:3000
```

Avec Docker Desktop, `docker compose up --build` fait la même chose sans installer Python.

Pour la CI, ajoute ton token Kaggle comme **secret** du repo GitHub (Settings → Secrets and variables → Actions) : `KAGGLE_API_TOKEN` pour un token récent (qui commence par `KGAT_`), ou la paire `KAGGLE_USERNAME` + `KAGGLE_KEY` d'un ancien `kaggle.json`. Sans secret, la CI saute Transfermarkt.

---

## M1 · Nettoyer et typer les sources : `staging/transfermarkt`, `staging/football_data`

**Objectif :** 7 modèles de staging. Il s'agit seulement de filtrer, renommer et typer : aucune jointure métier ni règle de gestion.

**Pièges :**
- Le fichier Transfermarkt contient **toutes** les compétitions et saisons. Filtre avec les variables du projet (`var(...)`), pas avec des valeurs écrites en dur.
- Chez football-data, toutes les colonnes arrivent en texte, et les dates sont au format jj/mm/aaaa.
- Dans `appearances`, plusieurs colonnes désignent un club. Une seule indique **pour qui** le joueur a joué ce jour-là.

**Question d'entretien :** pourquoi garder la couche brute intacte et tout transformer dans dbt, plutôt que de nettoyer dès la collecte ?

## M2 · Table de correspondance des équipes : `seeds/team_crosswalk.csv`

**Objectif :** les 18 clubs avec leur identifiant dans chaque source. La ligne de Leverkusen est donnée en exemple. Active `seeds` dans `dbt_project.yml`.

C'est une table de référence maintenue à la main. Les noms divergent trop pour un algorithme : « M'gladbach », « Ein Frankfurt », « 1. Fußballclub Heidenheim 1846 »…

**Question d'entretien :** à partir de combien d'entités cesses-tu de maintenir une table de correspondance à la main ? Qui en est responsable dans un club ?

## M3 · Rapprocher les matchs : `intermediate/matches`

**Objectif :** pour chacun des 34 matchs StatsBomb, retrouver le même match chez Transfermarkt et chez football-data. Le test `scores_agree` vérifie que les trois scores concordent.

**À réfléchir :** la date est-elle une bonne clé ? Pense aux matchs reportés. Quelle clé identifie un match de championnat **sans** dépendre de la date ?

## M4 · Rapprocher les joueurs : `intermediate/players` (le cœur du projet)

**Objectif :** relier les 460 joueurs StatsBomb à leur identifiant Transfermarkt.

**Ce qui rend l'exercice difficile :**
- StatsBomb donne souvent le nom complet à l'état civil, Transfermarkt le nom d'usage. « Eduardo dos Santos Haesler » est « Dudu », et Transfermarkt compte **six** Dudu.
- « Julian Chabot » est « Jeff Chabot », « Kouadio Emmanuel Koné » est « Manu Koné ».

Un rapprochement sur le nom seul, même avec une similarité floue, **échoue**. Cherche une clé fiable dans le contexte d'un match. Garde la similarité de noms pour **contrôler** les liens, pas pour les créer. Et vérifie qu'un joueur reçoit le même lien dans tous ses matchs (`games_linked = games_listed`).

**Livrable écrit :** ta méthode, les 10 liens les plus faibles selon la similarité de noms, et pourquoi tu leur fais confiance (ou pas).

**Question d'entretien :** comment ta méthode se comporterait-elle avec une source **sans** composition d'équipe, par exemple des rapports de scouts ?

## M5 · Les tables finales : `marts`

**Objectif :** un schéma en étoile.
- **Dimensions** : `dim_team`, `dim_player`, `dim_match`.
- **Faits** : `fct_player_match` (une ligne par joueur et par match joué) et `fct_team_match`.

**Pièges :**
- **Granularité :** chaque table a sa granularité, et les tests le vérifient.
- **Valeur « à date » :** la valeur marchande au début de saison, c'est la dernière estimation **avant** cette date, pas la plus récente.
- **Cotes :** les probabilités implicites contiennent la marge du bookmaker. Retire-la.
- **npxG :** un xG sans penalties.

**Question d'entretien :** pourquoi la clé joueur est-elle l'identifiant Transfermarkt plutôt que celui de StatsBomb ? Qu'est-ce que ce choix coûte ?

## M6 · Le rapport de rapprochement : `reports`

**Objectif :** `rpt_reconciliation`, une ligne par vérification et par entité : le score des matchs sur les 3 sources, les tirs par équipe, les buts et les cartons par joueur.

Tu vas trouver des écarts. Pour **chacun**, la question est : défaut de données, ou différence de définition entre fournisseurs ? Seul le score doit concorder à 100 %. Le reste se **documente**.

**Livrable écrit :** le taux de concordance par vérification, et l'explication de chaque type d'écart. C'est ta meilleure pièce de portfolio : c'est exactement le travail d'un data engineer en club.

## M7 (optionnel) · Le produit

Un tableau de bord Streamlit ou Evidence qui lit **uniquement** les tables finales : la saison de Leverkusen, les joueurs avec leur âge, leur valeur, leurs minutes et leur xG, et une page « qualité des données » branchée sur le rapport de M6.

---

## Ce qui est déjà en place (à savoir expliquer aussi)

| Élément | Où | Le choix et sa raison |
|---|---|---|
| **Couche brute** (le « lake ») | `src/cdp/sources/`, `data/lake/` | Un Parquet par table source, sans transformation. On peut tout reconstruire sans retélécharger. |
| **Staging StatsBomb** | `dbt/models/staging/statsbomb/` | Les champs JSON sont aplatis en SQL et matérialisés en tables. Une vue garderait le chemin relatif vers les fichiers bruts et casserait si on ouvre la base depuis un autre dossier. |
| **Tests génériques** | `dbt/macros/` | `row_count`, `covers`, `expected_rows`… Aucun paquet externe à télécharger. |
| **Orchestration** | `src/cdp/definitions.py` | Les tables brutes sont des assets Dagster, et dbt s'y branche automatiquement par le nom des sources. Les tests dbt deviennent des contrôles qualité (asset checks). Lancement planifié chaque lundi à 6 h. |
| **CI** | `.github/workflows/ci.yml` | Lint, collecte des sources, `dbt build` de tous les jalons activés, tests Python, et build de l'image Docker. |
