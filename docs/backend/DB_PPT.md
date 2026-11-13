# 🗄️ Schémas Relationnels — Présentation

> Schémas découpés par module fonctionnel pour une intégration facilitée en présentation.

---

## 1️⃣ Module `users` — Profil & Données Utilisateur

> Tables : `user`, `userdata`, `professionalstatus`, `socialstatus`, `genderidentities`

```mermaid
erDiagram
    USER {
        int id PK
        string username
        string email UK
        string hashed_password
        string role
        string ggid
        datetime created_at
    }

    USERDATA {
        int id PK
        int age
        int user_id FK
        int professional_status_id FK
        int social_status_id FK
        int gender_identity_id FK
    }

    PROFESSIONALSTATUS {
        int id PK
        string name
    }

    SOCIALSTATUS {
        int id PK
        string name
    }

    GENDERIDENTITIES {
        int id PK
        string name
    }

    USER ||--o| USERDATA : "has (cascade delete)"
    USERDATA }o--o| PROFESSIONALSTATUS : "references"
    USERDATA }o--o| SOCIALSTATUS : "references"
    USERDATA }o--o| GENDERIDENTITIES : "references"
```

---

## 2️⃣ Module `institution` — Institutions & Pouvoirs

> Tables : `institution`, `institutiontype`, `power`, `country`

```mermaid
erDiagram
    COUNTRY {
        int id PK
        string name UK
        string iso_code UK
    }

    POWER {
        int id PK
        string name UK
        string description
    }

    INSTITUTIONTYPE {
        int id PK
        string name UK
        string description
    }

    INSTITUTION {
        int id PK
        string name
        string description
        int country_id FK
        int power_id FK
        int institution_type_id FK
    }

    INSTITUTION }o--|| COUNTRY : "belongs to"
    INSTITUTION }o--|| POWER : "has power"
    INSTITUTION }o--|| INSTITUTIONTYPE : "has type"
```

---

## 3️⃣ Module `political_party` — Partis & Programmes Politiques

> Tables : `politicalparty`, `politicalprogram`, `electiontype`, `politicaltopic`, `domain`, `country`

```mermaid
erDiagram
    COUNTRY {
        int id PK
        string name UK
        string iso_code UK
    }

    DOMAIN {
        int id PK
        string name
        string description
    }

    ELECTIONTYPE {
        int id PK
        string name
    }

    POLITICALPARTY {
        int id PK
        string name
        string abbreviation
        string ideology_summary
        int country_id FK
    }

    POLITICALPROGRAM {
        int id PK
        string name
        int year
        int party_id FK
        int election_type_id FK
    }

    POLITICALTOPIC {
        int id PK
        string description
        int program_id FK
        int domain_id FK
    }

    POLITICALPARTY }o--|| COUNTRY : "based in"
    POLITICALPROGRAM }o--|| POLITICALPARTY : "published by"
    POLITICALPROGRAM }o--|| ELECTIONTYPE : "for election"
    POLITICALTOPIC }o--|| POLITICALPROGRAM : "part of"
    POLITICALTOPIC }o--|| DOMAIN : "belongs to domain"
```

---

## 4️⃣ Module `political_figure` — Personnalités Politiques

> Tables : `politicalfigure`, `politicalrole`, `politicalparty`, `country`

```mermaid
erDiagram
    COUNTRY {
        int id PK
        string name UK
        string iso_code UK
    }

    POLITICALPARTY {
        int id PK
        string name
        string abbreviation
        int country_id FK
    }

    POLITICALFIGURE {
        int id PK
        string name
        string last_name
        int party_id FK
        int country_id FK
    }

    POLITICALROLE {
        int id PK
        string name
        datetime start_date
        datetime end_date
        int figure_id FK
    }

    POLITICALFIGURE }o--|| POLITICALPARTY : "member of"
    POLITICALFIGURE }o--|| COUNTRY : "from"
    POLITICALROLE }o--|| POLITICALFIGURE : "held by"
```

---

## 5️⃣ Module `law` — Lois & Résultats de Vote

> Tables : `law`, `voteresult`, `institution`, `domain`, `country`

```mermaid
erDiagram
    COUNTRY {
        int id PK
        string name UK
        string iso_code UK
    }

    DOMAIN {
        int id PK
        string name
        string description
    }

    INSTITUTION {
        int id PK
        string name
        int country_id FK
        int power_id FK
        int institution_type_id FK
    }

    LAW {
        int id PK
        string title
        string subtitle
        string description
        int domain_id FK
        int country_id FK
        string source_url
        datetime created_at
        bool is_active
    }

    VOTERESULT {
        int id PK
        int law_id FK
        int institution_id FK
        int total_for
        int total_abstention
        int total_against
        bool adopted
        datetime vote_date
    }

    LAW }o--|| COUNTRY : "originates from"
    LAW }o--|| DOMAIN : "categorized by"
    VOTERESULT }o--|| LAW : "result for"
    VOTERESULT }o--|| INSTITUTION : "voted in"
```

---

## 6️⃣ Module `user_vote` — Votes Citoyens & Positions des Partis

> Tables : `uservote`, `partyvote`, `user`, `law`, `vote`, `politicalparty`

```mermaid
erDiagram
    VOTE {
        int id PK
        string position
    }

    USER {
        int id PK
        string username
        string email UK
    }

    LAW {
        int id PK
        string title
        bool is_active
    }

    POLITICALPARTY {
        int id PK
        string name
        string abbreviation
    }

    USERVOTE {
        int id PK
        int user_id FK
        int law_id FK
        int position_id FK
    }

    PARTYVOTE {
        int id PK
        int party_id FK
        int law_id FK
        int position_id FK
    }

    USERVOTE }o--|| USER : "cast by"
    USERVOTE }o--|| LAW : "on law"
    USERVOTE }o--|| VOTE : "position"
    PARTYVOTE }o--|| POLITICALPARTY : "stance of"
    PARTYVOTE }o--|| LAW : "on law"
    PARTYVOTE }o--|| VOTE : "position"
```

---

## 🔑 Table Pivot — `country` & `domain`

> Ces deux tables servent de référentiel partagé entre plusieurs modules.

```mermaid
erDiagram
    COUNTRY {
        int id PK
        string name UK
        string iso_code UK
    }

    DOMAIN {
        int id PK
        string name
        string description
    }

    INSTITUTION }o--|| COUNTRY : "belongs to"
    POLITICALFIGURE }o--|| COUNTRY : "from"
    POLITICALPARTY }o--|| COUNTRY : "based in"
    LAW }o--|| COUNTRY : "originates from"

    LAW }o--|| DOMAIN : "categorized by"
    POLITICALTOPIC }o--|| DOMAIN : "belongs to"
```
