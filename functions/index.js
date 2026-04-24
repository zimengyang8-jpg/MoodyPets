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

If possible, return valid JSON with:
{
  "mood": "...",
  "reason": "...",
  "suggestion": "..."
}

If the image is unclear or you cannot confidently use the JSON format, respond in 2-3 short sentences explaining what you can observe and what the owner could try next.

Do not exaggerate. Keep the response safe and gentle.
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

      let parsed;

      try {
            const jsonMatch = rawText.match(/\{[\s\S]*\}/);

            if (!jsonMatch) {
                throw new Error("No JSON found");
            }

            parsed = JSON.parse(jsonMatch[0]);

            return {
                mood: parsed.mood || "Unclear",
                reason: parsed.reason || "The image does not provide enough clear visual cues.",
                suggestion: parsed.suggestion || "Try uploading a clearer photo.",
                rawText: rawText,
                isStructured: true,
            };

        } catch (error) {
            logger.info("AI returned unstructured text:", rawText);

            return {
                mood: "Unclear",
                reason: rawText,
                suggestion: "Try another photo if you want a more specific result.",
                rawText: rawText,
                isStructured: false,
            };
        }

    } catch (error) {
      logger.error("analyzePetPhoto failed", error);
      throw new HttpsError("internal", "AI analysis failed.");
    }
  }
);