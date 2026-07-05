import type { Env } from '../index';
import { json } from '../index';

export interface OcrLine {
  label: string;
  amount_cents: number;
}

export interface CategorizedLine extends OcrLine {
  category: string;
}

const PREDEFINED_CATEGORIES = [
  'Alimentation',
  'Transport',
  'Santé & Pharmacie',
  'Hygiène & Entretien',
  'Logement & Factures',
  'Éducation',
  'Loisirs & Sorties',
  'Habillement',
  'Transferts & Épargne',
  'Autre',
] as const;

// [pattern, category] pairs — first match wins
const KEYWORD_MAP: Array<[RegExp, string]> = [
  [/yaourt|lait|pain|riz|sucre|sel|huile|pâte|pasta|biscuit|eau mineral|eau en bouteille|coca|jus|boisson|poulet|viande|poisson|légume|legume|fruit|tomate|oignon|ail|épice|epice|farine|haricot|mil|sorgho|maïs|mais|igname|plantain|café|cafe|thé|the\b|bière|biere|confiture|miel|beurre|fromage|oeuf|cereal|conserve|alimentation|épicerie|epicerie|supermarché|supermarche|marché|marche alimentaire/i, 'Alimentation'],
  [/taxi|bus|car|essence|carburant|pétrole|petrole|transport|billet|ferry|moto|trotro|woro woro|zem|zemidjan|gbakas|akwaba|diesel|gasoil|gasoïl|parking|péage|peage/i, 'Transport'],
  [/médicament|medicament|ordonnance|clinique|hôpital|hopital|pharmacie|comprimé|comprimes|sirop|pommade|santé|sante|consultation|docteur|médecin|medecin|infirmier|vaccin|analyse|radio|scanner|soin/i, 'Santé & Pharmacie'],
  [/savon|dentifrice|shampooing|shampoing|déodorant|deodorant|serviette hygiénique|serviette hygienique|couche|lessive|javel|nettoyant|détergent|detergent|brosse|peigne|crème|creme|lotion|parfum|hygiène|hygiene/i, 'Hygiène & Entretien'],
  [/loyer|électricité|electricite|eau et electricite|cie|sodeci|facture|abonnement|internet|wifi|téléphone fixe|telephone fixe|logement|gaz|propane|bouteille gaz|clé|cle appartement/i, 'Logement & Factures'],
  [/cahier|stylo|livre|école|ecole|formation|cours|inscription|scolarité|scolarite|scolaire|crayon|règle|regle|calculatrice|cartable|uniforme scolaire|manuel|bac|diplôme|diplome/i, 'Éducation'],
  [/cinéma|cinema|restaurant|maquis|snack|bar|loisir|sport|musique|jeu|sortie|concert|spectacle|divertissement|piscine|gym|salle de sport|karaoké|karaoke|boîte|boite de nuit|café culturel/i, 'Loisirs & Sorties'],
  [/tissu|chaussure|chemise|pantalon|robe|vêtement|vetement|habit|friperie|boutique mode|couturier|tailleur|pagnes|pagne|cravate|ceinture|sac à main|sac a main|sandales|baskets/i, 'Habillement'],
  [/recharge|crédit téléphone|credit telephone|momo|orange money|wave|moov|mtn money|transfert|envoi argent|western union|ria money|money gram|épargne|epargne|investissement|tontine/i, 'Transferts & Épargne'],
];

function categorizeByKeyword(label: string): string {
  for (const [pattern, category] of KEYWORD_MAP) {
    if (pattern.test(label)) return category;
  }
  return 'Autre';
}

async function categorizeWithMistral(lines: OcrLine[], apiKey: string): Promise<string[]> {
  const linesList = lines.map((l, i) => `${i + 1}. ${l.label}`).join('\n');

  const prompt = `Tu es un assistant de catégorisation de dépenses pour l'Afrique francophone.
Catégorise chaque ligne de reçu parmi ces catégories exactes uniquement :
Alimentation, Transport, Santé & Pharmacie, Hygiène & Entretien, Logement & Factures, Éducation, Loisirs & Sorties, Habillement, Transferts & Épargne, Autre

Lignes à catégoriser :
${linesList}

Réponds UNIQUEMENT avec un tableau JSON (index commence à 0) sans aucune explication :
[{"index":0,"category":"Alimentation"},{"index":1,"category":"Transport"}]`;

  const res = await fetch('https://api.mistral.ai/v1/chat/completions', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'mistral-small-latest',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 512,
      temperature: 0,
    }),
  });

  if (!res.ok) throw new Error(`Mistral error: ${res.status}`);

  const data = await res.json() as {
    choices?: Array<{ message?: { content?: string } }>;
  };

  const content = data.choices?.[0]?.message?.content ?? '';
  const jsonMatch = content.match(/\[[\s\S]*\]/);
  if (!jsonMatch) throw new Error('No JSON array in Mistral response');

  const parsed = JSON.parse(jsonMatch[0]) as Array<{ index: number; category: string }>;

  const categories = new Array<string>(lines.length).fill('Autre');
  for (const item of parsed) {
    if (
      typeof item.index === 'number' &&
      item.index >= 0 &&
      item.index < lines.length &&
      (PREDEFINED_CATEGORIES as readonly string[]).includes(item.category)
    ) {
      categories[item.index] = item.category;
    }
  }
  return categories;
}

export async function categorizeLines(
  lines: OcrLine[],
  env: Env,
): Promise<CategorizedLine[]> {
  if (lines.length === 0) return [];

  let categories: string[];

  if (env.MISTRAL_API_KEY) {
    try {
      categories = await categorizeWithMistral(lines, env.MISTRAL_API_KEY);
    } catch {
      categories = lines.map((l) => categorizeByKeyword(l.label));
    }
  } else {
    categories = lines.map((l) => categorizeByKeyword(l.label));
  }

  return lines.map((line, i) => ({
    ...line,
    category: categories[i] ?? 'Autre',
  }));
}

export async function handleCategorize(
  request: Request,
  env: Env,
): Promise<Response> {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }
  const body = await request.json<{ lines: OcrLine[] }>();
  const lines = await categorizeLines(body?.lines ?? [], env);
  return json(lines);
}
