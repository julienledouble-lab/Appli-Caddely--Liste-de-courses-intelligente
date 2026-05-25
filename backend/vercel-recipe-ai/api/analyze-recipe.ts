import {
  buildGeminiPrompt,
  extractJsonText,
  normalizeRecipeResponse,
  type GeminiRecipeResponse,
} from '../lib/recipe-response';

export const config = {
  runtime: 'edge',
};

const GEMINI_MODEL = 'gemini-2.5-flash';

export default async function handler(request: Request): Promise<Response> {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(),
    });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  try {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return jsonResponse({ error: 'GEMINI_API_KEY is missing.' }, 500);
    }

    const contentType = request.headers.get('content-type') ?? '';
    if (!contentType.toLowerCase().includes('multipart/form-data')) {
      return jsonResponse({ error: 'Content-Type must be multipart/form-data.' }, 400);
    }

    const formData = await request.formData();
    const images = formData
      .getAll('images')
      .filter((entry): entry is File => entry instanceof File);

    if (images.length === 0) {
      return jsonResponse({ error: 'At least one image is required.' }, 400);
    }

    const prompt = buildGeminiPrompt();
    const parts = await Promise.all(
      images.map(async (image) => {
        const receivedMimeType = image.type || 'application/octet-stream';
        const geminiMimeType = normalizeImageMimeType(image.name, receivedMimeType);
        console.info('[recipe-ai] image', {
          fileName: image.name,
          receivedMimeType,
          geminiMimeType,
        });

        if (!geminiMimeType) {
          throw new UnsupportedImageFormatError(
            'Format d’image non supporté. Utilise PNG, JPG, JPEG ou WEBP.',
          );
        }

        const data = arrayBufferToBase64(await image.arrayBuffer());
        return {
          inlineData: {
            mimeType: geminiMimeType,
            data,
          },
        };
      }),
    );

    const geminiResponse = await fetch(
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
                { text: prompt },
                ...parts,
              ],
            },
          ],
        }),
      },
    );

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      return jsonResponse(
        { error: `Gemini request failed: ${errorText}` },
        502,
      );
    }

    const payload = await geminiResponse.json();
    const rawJson = extractJsonText(payload);
    if (!rawJson) {
      return jsonResponse({ error: 'Gemini did not return any JSON content.' }, 502);
    }

    let parsed: GeminiRecipeResponse;
    try {
      parsed = JSON.parse(rawJson) as GeminiRecipeResponse;
    } catch {
      return jsonResponse({ error: 'Gemini did not return valid JSON.' }, 502);
    }

    const recipe = normalizeRecipeResponse(parsed);
    if (recipe.ingredients.length === 0) {
      return jsonResponse(
        { error: 'No usable ingredients were detected in the Gemini response.' },
        422,
      );
    }

    return jsonResponse(recipe, 200);
  } catch (error) {
    if (error instanceof UnsupportedImageFormatError) {
      return jsonResponse({ error: error.message }, 400);
    }
    const message =
      error instanceof Error ? error.message : 'Unexpected backend error.';
    return jsonResponse({ error: message }, 500);
  }
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders(),
      'Content-Type': 'application/json',
    },
  });
}

function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  let binary = '';
  const bytes = new Uint8Array(buffer);
  const chunkSize = 0x8000;

  for (let index = 0; index < bytes.length; index += chunkSize) {
    const chunk = bytes.subarray(index, index + chunkSize);
    binary += String.fromCharCode(...chunk);
  }

  return btoa(binary);
}

function normalizeImageMimeType(
  fileName: string,
  receivedMimeType: string,
): string | null {
  const normalizedMimeType = receivedMimeType.trim().toLowerCase();
  if (
    normalizedMimeType === 'image/png' ||
    normalizedMimeType === 'image/jpeg' ||
    normalizedMimeType === 'image/webp'
  ) {
    return normalizedMimeType;
  }

  if (
    normalizedMimeType !== '' &&
    normalizedMimeType !== 'application/octet-stream'
  ) {
    return null;
  }

  const normalizedName = fileName.trim().toLowerCase();
  if (normalizedName.endsWith('.png')) {
    return 'image/png';
  }
  if (normalizedName.endsWith('.jpg') || normalizedName.endsWith('.jpeg')) {
    return 'image/jpeg';
  }
  if (normalizedName.endsWith('.webp')) {
    return 'image/webp';
  }

  return null;
}

class UnsupportedImageFormatError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'UnsupportedImageFormatError';
  }
}
