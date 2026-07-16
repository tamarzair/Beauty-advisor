export default {
  async fetch(request, env) {
    // 1. Handle CORS Preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    if (request.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    try {
      const payload = await request.json();
      const { imageBase64, photoRequirement, profile } = payload;

      if (!imageBase64 || !photoRequirement || !profile) {
        return new Response(JSON.stringify({ error: "Missing required parameters" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }

      // Ensure API Key is bound to environment variables
      const apiKey = env.ANTHROPIC_API_KEY;
      if (!apiKey) {
        return new Response(JSON.stringify({ error: "Server misconfiguration: API key missing" }), {
          status: 500,
          headers: { "Content-Type": "application/json" },
        });
      }

      // 2. Synthesize High-Fashion Baddie Persona System Prompt
      const systemPrompt = `You are the ultimate elite personal beauty advisor. Your persona is a direct, razor-sharp synthesis of Jada Chavez, Hailey Bieber, Kim Kardashian, Shera Seven, Nicki Minaj, Pat McGrath, and Huda Kattan.
Tone: Blunt, unapologetically high-standard, sophisticated, and direct.
Rule 1: Never suggest product brands. Only specify raw formulation types (e.g., "lipid-rich repair cream", "alpha-arbutin corrector") or structural tailoring rules (e.g., "low-rise silhouettes to balance a short torso").
Rule 2: Focus heavily on the physical geometry of features, skin undertones, and body proportions. Provide strict, elite, actionable directives.`;

      // 3. Construct Claude 3.5 Sonnet API Request Payload
      const anthropicRequest = {
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1200,
        system: systemPrompt,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: "image/jpeg",
                  data: imageBase64
                }
              },
              {
                type: "text",
                text: `Analyze this photograph captured under the constraint: "${photoRequirement}".
                User Context:
                - Name: ${profile.name}
                - Height: ${profile.heightInches} inches
                - Declared Body Type: ${profile.bodyType}
                - Declared Skin Undertone: ${profile.skinUndertone}
                - Declared Hair Type: ${profile.hairType}

                Provide a structured, hyper-focused beauty and styling analysis. Detail exact aesthetic adjustments, style targets, and physical balancing guidelines.`
              }
            ]
          }
        ]
      };

      // 4. Dispatch to Anthropic API
      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
          "content-type": "application/json",
        },
        body: JSON.stringify(anthropicRequest),
      });

      const data = await response.json();

      if (!response.ok) {
        return new Response(JSON.stringify({ error: "Anthropic API Error", details: data }), {
          status: response.status,
          headers: { "Content-Type": "application/json" },
        });
      }

      // 5. Parse Claude response text block
      const rawTextResponse = data.content[0].text;

      // Structure output consistently for Swift client parsing
      const formattedResponse = {
        summary: "Baddie Blueprint Diagnostic Analysis Completed.",
        recommendations: rawTextResponse
      };

      return new Response(JSON.stringify(formattedResponse), {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      });

    } catch (error) {
      return new Response(JSON.stringify({ error: "Internal Server Error", details: error.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
  },
};
