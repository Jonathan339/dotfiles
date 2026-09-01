import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const HOME = process.env.HOME;
const DB = HOME + "/.local/share/opencode/opencode.db";
const SESS_DIR = HOME + "/MEGA/Obsidian/Sesiones";
const TAG = "sesion";

function rows(sql) {
  return execSync(`sqlite3 "${DB}" "${sql.replace(/"/g, '""')}"`)
    .toString().split("\n").map((l) => l.trim()).filter(Boolean);
}
function one(sql) {
  const r = execSync(`sqlite3 "${DB}" "${sql.replace(/"/g, '""')}"`).toString();
  return r === "" ? "" : r.slice(0, -1);
}
function formatDate(ms) {
  const d = new Date(parseInt(ms));
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

const TAG_MAP = [
  [/dotfiles|stow|rofi|sxhkd|keybinding|zsh|hyprland|xfce/, "linux-dotfiles"],
  [/scraping|bun|cheerio|playwright/, "scraping"],
  [/obsidian|vault|memoria|sesiones|recuerdas/, "obsidian-vault"],
  [/steam|zenity|dependencia/, "apps"],
  [/c (memory|estándar)|estandar-de-c|tree-sitter|estructura.*c|makefile|proyecto c/, "c-dev"],
  [/usb|sandisk|disco|iso|unrar|rar|dorking/, "archivos"],
  [/animeflv|anime|hentaila/, "anime"],
];
const NSFW_RE = /hentai|hentaila|porn|jxporn|nsfw|myfans|fantia|rule34|r34|xvideos/;
const NSFW_TOOLS = ["websearch", "webfetch", "browse"];
function isNsfw(text) {
  return NSFW_RE.test(text.toLowerCase());
}
function inferTags(title) {
  const tags = [TAG];
  const t = title.toLowerCase();
  for (const [re, tag] of TAG_MAP) if (re.test(t) && !tags.includes(tag)) tags.push(tag);
  return tags;
}
function isJunk(id, title) {
  const t = (title || "").toLowerCase();
  if (/^title request|^new session|^sin título/.test(t)) return true;
  // Saludos/holas sin sustancia: primero usamos el primer msg del usuario en syncSessions
  return false;
}

function firstUserMessage(id) {
  const msgs = rows(`SELECT id FROM message WHERE session_id='${id}' ORDER BY time_created;`);
  for (const mid of msgs) {
    let role = "";
    const d = one(`SELECT data FROM message WHERE id='${mid}';`);
    try { role = JSON.parse(d).role; } catch { continue; }
    if (role !== "user") continue;
    const parts = rows(`SELECT data FROM part WHERE message_id='${mid}' ORDER BY time_created;`);
    for (const p of parts) {
      try {
        const pr = JSON.parse(p);
        if (pr.type === "text" && pr.text && pr.text.trim()) return pr.text.trim();
      } catch { /* ignore */ }
    }
  }
  return "";
}

function deriveTitle(id, title) {
  let t = (title || "").trim();
  if (/^new session/i.test(t) || t.length < 4) {
    const fu = firstUserMessage(id);
    t = fu ? fu.replace(/[\n\r]+/g, " ").slice(0, 80) : "Sesión sin título";
  }
  return t;
}

function sessionTags(file) {
  try {
    const head = fs.readFileSync(path.join(SESS_DIR, file), "utf8").split("---")[1] || "";
    const m = head.match(/^\s*- (.+)$/gm) || [];
    return m.map((l) => l.replace(/^\s*-\s*/, ""));
  } catch { return []; }
}
function relLinks(file, tags) {
  if (!fs.existsSync(SESS_DIR)) return [];
  return fs.readdirSync(SESS_DIR)
    .filter((f) => f.endsWith(".md") && f !== file && f !== "Índice.md")
    .map((f) => f.replace(/\.md$/, ""))
    .filter((f) => {
      const t = sessionTags(f + ".md");
      return t.some((x) => tags.includes(x) && x !== TAG);
    });
}

function renderSession(id, title, directory, tCreated, tUpdated, agent, parentMd) {
  const isSub = agent === "explore";
  const cleanTitle = deriveTitle(id, title);
  const date = formatDate(tCreated);
  const dateEnd = formatDate(tUpdated);
  const clean = cleanTitle.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 60);
  const filename = `${date}_${clean}.md`;
  const tags = inferTags(cleanTitle);
  const nsfwFlag = isNsfw(cleanTitle);
  let allText = "";
  const blocks = [];
  const msgs = rows(`SELECT id FROM message WHERE session_id='${id}' ORDER BY time_created;`);
  for (const mid of msgs) {
    let role = "unknown";
    const d = one(`SELECT data FROM message WHERE id='${mid}';`);
    try { role = JSON.parse(d).role; } catch { /* ignore */ }
    const parts = rows(`SELECT data FROM part WHERE message_id='${mid}' ORDER BY time_created;`);
    const texts = [], tools = [];
    for (const p of parts) {
      let pr;
      try { pr = JSON.parse(p); } catch { continue; }
      if (pr.type === "text" && pr.text) {
        texts.push(pr.text.trim());
        allText += pr.text + "\n";
      }
      else if (pr.type === "tool" && pr.tool) {
        const input = JSON.stringify(pr.state?.input || {});
        const s = pr.state?.status === "completed" ? "" : (pr.state?.status || "");
        tools.push(`\`${pr.tool}\` ${s} ${input.length > 90 ? input.slice(0, 90) + "…" : input}`);
        if (NSFW_TOOLS.includes(pr.tool)) allText += input + "\n";
      }
    }
    if (texts.length) blocks.push(`## ${role === "user" ? "Usuario" : role === "assistant" ? "Asistente" : role}\n\n${texts.join("\n\n")}`);
    if (tools.length) blocks.push(`<details><summary>Herramientas (${tools.length})</summary>\n\n${tools.map((t) => "- " + t).join("\n")}\n\n</details>`);
  }
  if (isNsfw(allText) || nsfwFlag) tags.push("nsfw");
  const rels = relLinks(filename, tags);
  let md = `---
tags:
${tags.map((t) => `  - ${t}`).join("\n")}
fecha: ${date}
tipo: sesion
nsfw: ${tags.includes("nsfw")}
---

# Sesión ${date} — ${cleanTitle.charAt(0).toUpperCase() + cleanTitle.slice(1)}

- **Fecha:** ${date}${dateEnd !== date ? ` al ${dateEnd}` : ""}
- **Sesión ID:** \`${id}\`
- **Directorio:** \`${directory}\`
${isSub ? "- **Tipo:** subagente (@explore)\n" : ""}---

${blocks.join("\n\n")}
`;
  if (rels.length) md += `\n## Relaciones\n\n${rels.map((r) => "- [[Sesiones/" + r + "]]").join("\n")}\n`;
  return { filename, md: md.replace(/\n{3,}/g, "\n\n").replace(/^\n/, "").trim() + "\n", date };
}

function existsWithDate(file, tUpdated) {
  const p = path.join(SESS_DIR, file);
  if (!fs.existsSync(p)) return false;
  const hasFront = fs.readFileSync(p, "utf8").startsWith("---\n");
  if (!hasFront) return false;
  const hasNsfwMeta = fs.readFileSync(p, "utf8").includes("nsfw: ");
  if (!hasNsfwMeta) return false;
  const mtime = Math.floor(fs.statSync(p).mtimeMs / 1000);
  return mtime >= Math.floor(parseInt(tUpdated) / 1000) - 5;
}

function findFileWithSessionId(id) {
  if (!fs.existsSync(SESS_DIR)) return null;
  for (const f of fs.readdirSync(SESS_DIR)) {
    if (!f.endsWith(".md") || f === "Índice.md") continue;
    try {
      const content = fs.readFileSync(path.join(SESS_DIR, f), "utf8");
      if (content.includes(`\`${id}\``)) return f;
    } catch { /* ignore */ }
  }
  return null;
}

function countSubstantialMessages(id) {
  const msgs = rows(`SELECT id FROM message WHERE session_id='${id}' ORDER BY time_created;`);
  let textBlocks = 0;
  for (const mid of msgs) {
    const parts = rows(`SELECT data FROM part WHERE message_id='${mid}' ORDER BY time_created;`);
    let hasText = false;
    for (const p of parts) {
      try {
        if (JSON.parse(p).type === "text") { hasText = true; break; }
      } catch { /* ignore */ }
    }
    if (hasText) textBlocks++;
  }
  return textBlocks;
}

function isJunkSession(id, title, directory) {
  const t = (title || "").toLowerCase().trim();
  const generic = /^new session|^title request|^sin título/.test(t);
  const nText = countSubstantialMessages(id);
  // Sesiones genéricas con contenido real: no son basura (ej. "New session" con 40 msgs)
  if (generic && nText >= 4) return false;
  if (generic) return true;
  const fu = firstUserMessage(id).toLowerCase().trim();
  const pureGreeting = /^(hola|saludo|hola\s|saludo\s|que necesitas|nnm|h\s*$)/.test(fu) || fu === "";
  // Saludo de ida y vuelta (2 bloques) sin tema = basura; exige 3+ para considerarla real
  if (pureGreeting && nText < 3) return true;
  return false;
}

function syncSessions() {
  if (!fs.existsSync(SESS_DIR)) fs.mkdirSync(SESS_DIR, { recursive: true });
  const out = [];
  const sessions = rows(`SELECT id || '§' || replace(title,'|','/') || '§' || directory || '§' || time_created || '§' || time_updated || '§' || agent FROM session ORDER BY time_created;`);
  for (const s of sessions) {
    const [id, title, directory, tCreated, tUpdated, agent] = s.split("§");
    if (isJunkSession(id, title, directory)) continue;
    // Ya exportada: respetar el archivo existente (no renombrar ni regenerar)
    const existing = findFileWithSessionId(id);
    if (existing) continue;
    const { filename, md, date } = renderSession(id, title, directory, tCreated, tUpdated, agent);
    if (existsWithDate(filename, tUpdated)) continue;
    fs.writeFileSync(path.join(SESS_DIR, filename), md);
    out.push(`${date} | ${title.slice(0, 50)}`);
  }
  return out;
}

export const SessionExporter = async () => {
  return {
    event: async ({ event }) => {
      if (event.type !== "session.idle") return;
      try {
        syncSessions();
      } catch {
        // silencioso: no interrumpe la entrada del usuario
      }
    },
  };
};