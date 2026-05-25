# Backend Vercel Recette IA pour Caddely

Ce dossier contient un backend Vercel minimal pour analyser une ou plusieurs photos de recette avec Gemini Vision, puis renvoyer un JSON compatible avec `RecipeAiExtractionService` dans Flutter.

## 1. Installer les dependances

Dans un terminal :

```powershell
cd "C:\Users\Ju\Documents\Projets informatique\Liste de courses intelligente - Appli\backend\vercel-recipe-ai"
npm install -g vercel
```

Ce projet n'a pas de dependances runtime obligatoires en plus de Vercel CLI.

## 2. Variable d'environnement a creer

Sur Vercel, ajouter :

- `GEMINI_API_KEY`

Cette cle ne doit jamais etre ajoutee dans Flutter.

## 3. Lancer en local avec Vercel

```powershell
cd "C:\Users\Ju\Documents\Projets informatique\Liste de courses intelligente - Appli\backend\vercel-recipe-ai"
vercel dev
```

Si besoin, connecter d'abord le projet :

```powershell
vercel login
vercel link
```

## 4. Deployer sur Vercel

Depuis le dossier backend :

```powershell
cd "C:\Users\Ju\Documents\Projets informatique\Liste de courses intelligente - Appli\backend\vercel-recipe-ai"
vercel
vercel env add GEMINI_API_KEY
vercel --prod
```

L'URL finale ressemblera a :

```text
https://ton-projet.vercel.app
```

L'endpoint Flutter a utiliser sera :

```text
https://ton-projet.vercel.app/api/analyze-recipe
```

## 5. Routes disponibles

### Health check

```text
GET /api/health
```

Reponse :

```json
{ "ok": true }
```

### Analyse recette

```text
POST /api/analyze-recipe
Content-Type: multipart/form-data
Champ fichiers : images
```

Tu peux envoyer une ou plusieurs images sous le meme champ `images`.

## 6. Tester l'endpoint

### Verifier la route health

```powershell
Invoke-WebRequest -UseBasicParsing https://TON-ENDPOINT/api/health
```

### Tester l'analyse avec curl

```powershell
curl.exe -X POST "https://TON-ENDPOINT/api/analyze-recipe" ^
  -F "images=@C:\chemin\image1.jpg" ^
  -F "images=@C:\chemin\image2.jpg"
```

La reponse attendue est un JSON de ce type :

```json
{
  "title": "Pates au poulet",
  "servings": 2,
  "prepTimeMinutes": 10,
  "cookTimeMinutes": 20,
  "ingredients": [
    {
      "name": "Pates",
      "quantity": "200",
      "unit": "g",
      "category": "epicerie",
      "isSelected": true
    }
  ],
  "steps": [
    "Faire cuire les pates."
  ],
  "source": "gemini_vision"
}
```

## 7. Connecter Flutter a l'endpoint

Lancer Flutter avec :

```powershell
C:\Users\Ju\flutter\bin\flutter.bat run --dart-define=RECIPE_AI_ENDPOINT=https://TON-ENDPOINT/api/analyze-recipe
```

Exemple :

```powershell
C:\Users\Ju\flutter\bin\flutter.bat run --dart-define=RECIPE_AI_ENDPOINT=https://caddely-recipe-ai.vercel.app/api/analyze-recipe
```

## 8. Notes importantes

- Le backend analyse toutes les images comme une seule recette.
- Gemini doit renvoyer uniquement du JSON.
- Le backend normalise la reponse pour proteger Flutter des champs manquants.
- Si Gemini ne renvoie aucun ingredient exploitable, le backend renvoie une erreur propre.
