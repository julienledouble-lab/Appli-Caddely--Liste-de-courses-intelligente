/*
  Example backend function for Caddely recipe AI analysis.
  This file is illustrative only and is not used by the Flutter build.

  Required environment variable:
  - GEMINI_API_KEY
*/

type GeminiRecipeResponse = {
  title?: string;
  servings?: number;
  prepTimeMinutes?: number;
  cookTimeMinutes?: number;
  ingredients?: Array<{
    name?: string;
    quantity?: string;
    unit?: string;
    category?: string;
    isSelected?: boolean;
  }>;
  steps?: string[];
  source?: string;
};

const GEMINI_MODEL = 'gemini-2.5-flash';

export async function analyzeRecipeRequest(req: Request): Promise<Response> {
  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return jsonResponse({ error: 'GEMINI_API_KEY is missing.' }, 500);
    }

    const formData = await req.formData();
    const images = formData.getAll('images').filter((entry): entry is File => entry instanceof File);
    if (images.length === 0) {
      return jsonResponse({ error: 'At least one image is required.' }, 400);
    }

    const parts = await Promise.all(
      images.map(async (image) => {
        const buffer = Buffer.from(await image.arrayBuffer());
        return {
          inlineData: {
            mimeType: image.type || 'image/jpeg',
            data: buffer.toString('base64'),
          },
        };
      }),
    );

    const prompt = `
Analyse ces images comme une seule recette.
Retourne uniquement un JSON valide, sans markdown, sans texte autour.

Le JSON doit contenir :
- title
- servings
- prepTimeMinutes
- cookTimeMinutes
- ingredients
- steps

Pour ingredients, chaque entree doit contenir :
- name
- quantity
- unit
- category
- isSelected

N'invente pas d'ingredients.
Si une information est incertaine, laisse-la vide ou mets une valeur raisonnable mais corrigible.
`;

    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          generationConfig: {
            responseMimeType: 'application/json',
          },
          contents: [
            {
              role: 'user',
              parts: [
                { text: prompt.trim() },
                ...parts,
              ],
            },
          ],
        }),
      },
    );

    if (!response.ok) {
      const text = await response.text();
      return jsonResponse({ error: `Gemini request failed: ${text}` }, 502);
    }

    const payload = await response.json();
    const rawText =
      payload?.candidates?.[0]?.content?.parts?.find((part: { text?: string }) => part?.text)?.text ?? '';

    let parsed: GeminiRecipeResponse;
    try {
      parsed = JSON.parse(rawText);
    } catch {
      return jsonResponse({ error: 'Gemini did not return valid JSON.' }, 502);
    }

    return jsonResponse({
      title: parsed.title ?? 'Recette importee',
      servings: parsed.servings ?? 1,
      prepTimeMinutes: parsed.prepTimeMinutes ?? 0,
      cookTimeMinutes: parsed.cookTimeMinutes ?? 0,
      ingredients: Array.isArray(parsed.ingredients) ? parsed.ingredients : [],
      steps: Array.isArray(parsed.steps) ? parsed.steps : [],
      source: 'gemini_vision',
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error';
    return jsonResponse({ error: message }, 500);
  }
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
    },
  });
}
