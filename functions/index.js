const { setGlobalOptions } = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const OpenAI = require("openai");

setGlobalOptions({ maxInstances: 10 });

// ✅ Define secret (modern way)
const openaiKey = defineSecret("OPENAI_API_KEY");

exports.analyzePetPhoto = onCall(
  { secrets: [openaiKey] }, // 👈 attach secret to function
  async (request) => {

    const { imageURL } = request.data || {};

    // ✅ auth check
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    // ✅ input check
    if (!imageURL) {
      throw new HttpsError("invalid-argument", "Missing imageURL.");
    }

    try {
      // ✅ Initialize client INSIDE function (important)
      const client = new OpenAI({
        apiKey: process.env.OPENAI_API_KEY,
      });

      const response = await client.chat.completions.create({
        model: "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: `
Analyze this pet image conservatively.

Return ONLY valid JSON:
{
  "mood": "...",
  "reason": "...",
  "suggestion": "..."
}

Rules:
- Do not exaggerate
- Keep answers short
- No extra text outside JSON
                `.trim(),
              },
              {
                type: "image_url",
                image_url: {
                  url: imageURL,
                },
              },
            ],
          },
        ],
      });

      const rawText = response.choices[0].message.content;

      logger.info("AI raw output received");

      // ✅ (Optional but recommended) parse JSON safely
      let parsed;
      try {
        parsed = JSON.parse(rawText);
      } catch {
        parsed = { raw: rawText }; // fallback if AI misbehaves
      }

      return parsed;

    } catch (error) {
      logger.error("analyzePetPhoto failed", error);
      throw new HttpsError("internal", "AI analysis failed.");
    }
  }
);