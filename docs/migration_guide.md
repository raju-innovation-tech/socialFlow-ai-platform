# SocialFlow AI – Alembic Database Migration Guide

## 1. Migration Directory
Located at `backend/alembic/versions/`.

## 2. Applying Migrations
To upgrade the connected database to the latest schema:
```powershell
alembic -c backend/alembic.ini upgrade head
```

## 3. Rolling Back
To rollback the latest revision:
```powershell
alembic -c backend/alembic.ini downgrade -1
```
To rollback completely to base:
```powershell
alembic -c backend/alembic.ini downgrade base
```

## 4. Creating New Migrations
When adding new models or modifying columns in `app/models/`:
```powershell
alembic -c backend/alembic.ini revision --autogenerate -m "describe_changes"
```
Review the generated file in `backend/alembic/versions/` before applying.

