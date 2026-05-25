const String recipeAiEndpoint = String.fromEnvironment('RECIPE_AI_ENDPOINT');

bool get isRecipeAiConfigured => recipeAiEndpoint.trim().isNotEmpty;
