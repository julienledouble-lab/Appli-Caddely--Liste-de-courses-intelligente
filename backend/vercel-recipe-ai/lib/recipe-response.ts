export type GeminiRecipeResponse = {
  title?: string;
  servings?: number | string;
  prepTimeMinutes?: number | string;
  cookTimeMinutes?: number | string;
  ingredients?: Array<{
    name?: string;
    quantity?: string | number;
    unit?: string;
    category?: string;
    isSelected?: boolean;
  }>;
  steps?: string[];
  source?: string;
};

const allowedCategories = new Set([
  'fruits_et_legumes',
  'frais',
  'epicerie',
  'boissons',
  'hygiene',
  'maison',
  'surgeles',
  'autre',
]);

export function buildGeminiPrompt(): string {
  return `
Analyse toutes ces images comme une seule recette.
Retourne uniquement un JSON valide.
Ne retourne pas de markdown.
Ne retourne pas de commentaire autour.
N'invente pas d'ingredients.

Structure JSON attendue :
{
  "title": "string",
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
    "Faire cuire les pates.",
    "Preparer la sauce."
  ],
  "source": "gemini_vision"
}

Contraintes :
- separe proprement les ingredients
- garde les etapes dans l'ordre
- si une information manque, laisse une valeur simple et corrigible
- categories autorisees : fruits_et_legumes, frais, epicerie, boissons, hygiene, maison, surgeles, autre
`.trim();
}

export function normalizeRecipeResponse(raw: GeminiRecipeResponse) {
  const ingredients = Array.isArray(raw.ingredients)
    ? raw.ingredients
        .map((ingredient) => ({
          name: normalizeText(ingredient?.name),
          quantity: normalizeQuantity(ingredient?.quantity),
          unit: normalizeText(ingredient?.unit),
          category: normalizeCategory(ingredient?.category),
          isSelected: ingredient?.isSelected ?? true,
        }))
        .filter((ingredient) => ingredient.name.length > 0)
    : [];

  const steps = Array.isArray(raw.steps)
    ? raw.steps
        .map((step) => normalizeText(step))
        .filter((step) => step.length > 0)
    : [];

  return {
    title: normalizeText(raw.title) || 'Recette importee',
    servings: normalizeInteger(raw.servings, 1),
    prepTimeMinutes: normalizeInteger(raw.prepTimeMinutes, 0),
    cookTimeMinutes: normalizeInteger(raw.cookTimeMinutes, 0),
    ingredients,
    steps,
    source: 'gemini_vision',
  };
}

export function extractJsonText(payload: unknown): string {
  const directText = (payload as any)?.candidates?.[0]?.content?.parts?.find(
    (part: { text?: string }) =>
      typeof part?.text === 'string' && part.text.trim().length > 0,
  )?.text;

  if (typeof directText === 'string' && directText.trim().length > 0) {
    return directText;
  }

  return '';
}

function normalizeText(value: unknown): string {
  if (typeof value !== 'string') {
    return '';
  }

  return value.trim();
}

function normalizeQuantity(value: unknown): string {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Number.isInteger(value)
      ? value.toString()
      : value.toFixed(2).replace(/\.?0+$/, '');
  }

  if (typeof value === 'string') {
    return value.trim();
  }

  return '';
}

function normalizeInteger(value: unknown, fallback: number): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.max(0, Math.round(value));
  }

  if (typeof value === 'string') {
    const parsed = Number.parseInt(value.trim(), 10);
    if (Number.isFinite(parsed)) {
      return Math.max(0, parsed);
    }
  }

  return fallback;
}

function normalizeCategory(value: unknown): string {
  if (typeof value !== 'string') {
    return 'autre';
  }

  const normalized = value
    .trim()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replaceAll('&', 'et')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');

  if (normalized === 'fruits_legumes' || normalized === 'fruits_et_legumes') {
    return 'fruits_et_legumes';
  }

  if (allowedCategories.has(normalized)) {
    return normalized;
  }

  return 'autre';
}
