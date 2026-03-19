const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Scoring par mots-clés (gratuit)
const RULES = [
  { category: "Chaussures", keywords: ["shoe", "sneaker", "boot", "chaus", "nike dunk", "air max", "runner"] },
  { category: "Pantalon", keywords: ["pantalon", "jean", "denim", "trouser", "pants", "cargo", "chino"] },
  { category: "Short", keywords: ["short", "bermuda"] },
  { category: "Haut", keywords: ["tshirt", "t-shirt", "tee", "shirt", "chemise", "pull", "sweat", "hoodie", "veste", "jacket", "coat"] },
  { category: "Accessoires", keywords: ["cap", "casquette", "hat", "belt", "ceinture", "bag", "sac", "watch", "montre"] }
];

function suggestFromText(text, allowedCategories) {
  const t = (text || "").toLowerCase();

  let best = { category: "Autre", score: 0 };

  for (const rule of RULES) {
    if (allowedCategories && allowedCategories.length && !allowedCategories.includes(rule.category)) continue;

    let score = 0;
    for (const kw of rule.keywords) {
      if (t.includes(kw)) score += 1;
    }

    if (score > best.score) best = { category: rule.category, score };
  }

  // Confidence simple: 0..1 (plus il y a de mots-clés matchés, plus c’est “sûr”)
  const confidence = Math.min(1, best.score / 3);

  if (best.score === 0) return { category: allowedCategories?.includes("Autre") ? "Autre" : "Autre", confidence: 0 };

  return { category: best.category, confidence };
}

exports.suggestCategory = functions.https.onCall(async (data, context) => {
  const imageUrl = (data.imageUrl || "").trim();
  const allowedCategories = Array.isArray(data.allowedCategories) ? data.allowedCategories : [];

  if (!imageUrl.startsWith("http")) {
    throw new functions.https.HttpsError("invalid-argument", "imageUrl invalide");
  }

  // On analyse juste le texte de l'URL (gratuit)
  return suggestFromText(imageUrl, allowedCategories);
});
