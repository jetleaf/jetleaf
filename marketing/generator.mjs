#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const MARKETING_DIR = __dirname;

const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const PREFERRED_MODEL = process.env.GEMINI_MODEL;

if (!GEMINI_API_KEY) {
  console.error('❌ Error: GEMINI_API_KEY environment variable is missing.');
  console.error('Usage: GEMINI_API_KEY="your-key" node generator.mjs [daily-tips|newsletter|article|weekend-guide]');
  process.exit(1);
}

const targetType = process.argv[2] || 'daily-tips';

async function resolveCandidateModels(apiKey, preferred) {
  const candidates = [];
  if (preferred) candidates.push(preferred);

  try {
    const res = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`, {
      headers: { 'Connection': 'close' }
    });
    if (res.ok) {
      const data = await res.json();
      const available = (data.models || [])
        .filter(m => m.supportedGenerationMethods && m.supportedGenerationMethods.includes('generateContent'))
        .map(m => m.name.replace(/^models\//, ''));

      console.log(`📋 Available models for key (${available.length} found)`);

      const priorityOrder = [
        'gemini-3.8-flash',
        'gemini-3.7-flash',
        'gemini-3.6-flash',
        'gemini-3.5-flash',
        'gemini-flash-latest',
        'gemini-3.1-flash-lite',
        'gemini-2.5-flash',
        'gemini-2.0-flash'
      ];

      for (const m of priorityOrder) {
        if (available.includes(m) && !candidates.includes(m)) {
          candidates.push(m);
        }
      }

      for (const m of available) {
        if (!candidates.includes(m) && m.includes('flash')) {
          candidates.push(m);
        }
      }
    }
  } catch (err) {
    console.warn(`⚠️ Warning: Could not list models (${err.message}).`);
  }

  if (candidates.length === 0) {
    candidates.push('gemini-3.8-flash', 'gemini-3.7-flash', 'gemini-flash-latest');
  }

  return candidates;
}

const SYSTEM_CONTEXT = `
You are the Lead Developer Advocate, Content Strategist, and Growth Director for Jetleaf (jetleaf.hapnium.com / github.com/hapnium/jetleaf).

[JETLEAF PLATFORM CONTEXT & FRAMEWORK BRAIN]
- Platform: Jetleaf is the modern, modular, enterprise-grade backend framework for Dart ("Spring Boot / NestJS for Dart").
- Core Philosophy:
  1. Full-Stack Dart: Uniting Flutter frontend and Dart backend with shared data models, typed DTOs, and zero language context-switching.
  2. Enterprise Architecture: Inversion of Control (IoC), typed scoped Pods, declarative annotations, lifecycle hooks, and robust multi-profile configurations.
  3. Lightning Developer Experience: Resident JetleafVM daemon (\`jl dev\`, \`jl run\`, \`jl test\`) providing sub-second isolate pre-warming and hot reload.
  4. Production Observability: Built-in Actuator (\`jetleaf_actuator\`) exposing health checks, JVM/Isolate metrics, memory, and telemetry.
  5. AI-First & Vibecoding Ready: Strict type contracts and Model Context Protocol (\`jetleaf_mcp\`) enabling AI agents (Cursor, Claude Desktop, Antigravity) to scaffold and self-heal production servers autonomously.

[MONOREPO PACKAGES & ECOSYSTEM MATRIX]
- \`jetleaf\` (Root Package): \`JetleafApplication.run\`, bootstrap lifecycle, configuration parsers (\`application.yaml\`), environment profiles, logging, and graceful shutdown signal handlers (\`SIGINT\`, \`SIGTERM\`).
- \`libraries/jetleaf_core\`: The heart of the IoC container. Typed Pods (\`@Pod\`), configuration classes (\`@Configuration\`), constructor injection, dependency injection, reflectable metadata, and runtime converters.
- \`libraries/jetleaf_tools\`: Developer tooling and CLI (\`jl\`). Houses \`JetleafVM\` resident daemon, AST project scanners, cache managers, and isolated test drivers.
- \`packages/jetleaf_actuator\`: Production monitoring system (Spring Actuator equivalent). Exposes \`/actuator/health\`, \`/actuator/metrics\`, \`/actuator/info\`, isolate memory, CPU load, and thread diagnostics.
- \`packages/jetleaf_web\`: Web MVC & REST framework. Annotations: \`@RestController\`, \`@RequestMapping\`, \`@GetMapping\`, \`@PostMapping\`, \`@PutMapping\`, \`@DeleteMapping\`, \`@PathVariable\`, \`@RequestParam\`, \`@RequestBody\`, \`ResponseEntity\`, middleware, CORS, and content negotiation.
- \`packages/jetleaf_retry\`: Declarative fault tolerance with \`@Retryable\`, exponential backoff policies, recovery handlers, and circuit breakers.
- \`packages/jetleaf_validation\`: Enterprise data validation. Annotations: \`@Valid\`, \`@NotNull\`, \`@Size\`, \`@Email\`, \`@Pattern\`, \`@Min\`, \`@Max\`, and custom constraint validators.
- \`packages/jetson\`: Ultra-fast JSON serialization, deserialization, and schema mappings.
- \`packages/jtl\`: Jetleaf Template Language / server-side rendering view engine.
- \`packages/jetleaf_data\` (Roadmap): Spring Data for Dart. Repository abstraction (\`CrudRepository\`, \`JetleafRepository\`), dynamic query derivation (\`findByEmail\`), multi-dialect support (PostgreSQL, MySQL, SQLite, MongoDB, Redis), connection pooling, and declarative \`@Transactional\` management.
- \`packages/jetleaf_security\` (Roadmap): Spring Security 6+ for Dart. SecurityFilterChain pipeline, CORS, CSRF, rate-limiting, stateless JWT engine (RS256, HS256), OAuth2/OIDC resource server, Argon2id password hashing, and method security (\`@PreAuthorize\`).
- \`packages/jetleaf_mcp\` (Roadmap): Model Context Protocol server exposing project scaffolding, AST inspection, route tables, and warm-VM test runners to Cursor, Windsurf, Claude Desktop, and Antigravity.

[AUDIENCE PERSONAS]
1. Full-Stack Flutter Developers: 2M+ mobile/web Flutter engineers tired of maintaining backends in Node.js, Go, or Python.
2. Enterprise Backend Architects: Engineers with Java/Spring Boot, C#/.NET, or NestJS backgrounds looking for clean IoC, dependency injection, and production telemetry in Dart.
3. AI-First Builders & Vibecoders: Developers building applications purely with AI prompts who need strict types, zero-boilerplate annotations, and deterministic compiler feedback.
4. Solo Founders & CTOs: Startups wanting end-to-end type safety from the database to the mobile screen with maximum developer velocity.

[BRAND VOICE & TONE]
- Technical, authoritative, modern, inspiring, and developer-friendly.
- "Show, Don't Tell": Always prioritize real Dart code snippets, terminal commands, and concrete architecture over vague buzzwords.
- Clear contrasts: Highlight the elegance of declarative annotations over messy manual routing; showcase the speed of \`jl dev\` hot reload.
- Key Links: https://jetleaf.hapnium.com | https://github.com/hapnium/jetleaf | pub.dev/packages/jetleaf
`;

const PROMPTS = {
  'daily-tips': (todayStr, dayOfWeek) => `
${SYSTEM_CONTEXT}

[YOUR TASK]
Generate today's "Jetleaf Daily Tip" formatted as a 6-slide social media carousel (for LinkedIn PDF carousels, Instagram, and Twitter/X slide cards) + high-converting social caption.

Today is ${dayOfWeek}, ${todayStr}.
Follow this weekday theme rotation across the Jetleaf stack:
- Monday: IoC & Core Architecture (Pods, @Pod, @Configuration, constructor injection, clean architecture)
- Tuesday: Web & REST APIs (@RestController, request validation, error handling, content negotiation)
- Wednesday: Developer Velocity & Tooling (jl dev resident VM, isolate pre-warming, hot reload, sub-100ms iterations)
- Thursday: Production & Telemetry (jetleaf_actuator, health probes, isolate memory tracking, metrics)
- Friday: Full-Stack Dart & Flutter Integration (shared DTOs, type-safe API consumption, zero context switching)
- Saturday: AI Agents & Vibecoding (jetleaf_mcp, prompt-driven server generation, autonomous test healing)
- Sunday: Resilience, Data & Security (declarative retries @Retryable, jetleaf_data, jetleaf_security, @Transactional)

[OUTPUT FORMAT]
Produce a clean Markdown file with:
# Jetleaf Daily Tip — ${dayOfWeek} (${todayStr})
## Slide Breakdown
- Slide 1: Bold Title / High-Impact Hook (with Jetleaf logo/branding note)
- Slide 2: The Architectural Problem / Anti-Pattern (What developers usually struggle with)
- Slide 3: The Jetleaf Way — Clean Code Example (formatted Dart snippet demonstrating annotations or CLI)
- Slide 4: Deep Dive / How it Works Under the Hood (IoC container, AST scanner, or isolate execution)
- Slide 5: Pro-Tip / Enterprise Best Practice (Production tip, performance optimization, or testing hint)
- Slide 6: Outro & Call to Action (Try it: \`dart pub global activate jetleaf_tools\` | jetleaf.hapnium.com)
## Visual Design Notes (Canva/Figma layout, dark mode colors #0F172A / emerald accents #10B981, typography)
## Ready-to-Copy Social Caption (with code snippets, emojis, hashtags #FlutterDev #Dart #FullStackDart #Backend #WebDev #Jetleaf, and an engaging question prompt)
`,

  'newsletter': (todayStr) => `
${SYSTEM_CONTEXT}

[YOUR TASK]
Draft this week's edition of "The Full-Stack Dart Dispatch" (The Official Jetleaf Newsletter), delivered to Flutter developers, backend engineers, and engineering leaders worldwide.
Date: ${todayStr}

[NEWSLETTER STRUCTURE REQUIRED]
1. Subject Lines: 3 catchy, high-open-rate subject line options (with emojis) + 1 preview snippet (under 90 chars).
2. The Lead Story / Opening Essay: 2–3 sharp paragraphs exploring the state of full-stack Dart, the rise of Dart on the backend, or modern architecture trends.
3. Feature Deep-Dive / Code Spotlight: Detailed breakdown of a specific Jetleaf superpower (e.g. resident JetleafVM isolate pre-warming, /actuator/health telemetry, or declarative @RestController routing). Include a complete, elegant Dart code snippet.
4. Monorepo Package Highlight: Spotlight on one package (e.g. jetleaf_actuator, jetleaf_web, jetleaf_retry, jetleaf_validation, or roadmap jetleaf_data/jetleaf_mcp).
5. Vibecoder Corner (AI + Dart): A quick prompt or tip for building Jetleaf backends with AI tools (Cursor, Claude, Antigravity).
6. Community Q&A / Pro-Tip of the Week: Concise answer to a common developer question (e.g., "How does Jetleaf hot reload work without restarting the whole process?").
7. Outro & Call to Action: Links to Star on GitHub (github.com/hapnium/jetleaf), read documentation (jetleaf.hapnium.com), and join the Discord community.
`,

  'article': (todayStr) => `
${SYSTEM_CONTEXT}

[YOUR TASK]
Write an in-depth, authoritative, thought-leadership technical essay (1,400 to 1,800 words) for Jetleaf suitable for Substack, Medium, dev.to, and LinkedIn Articles.
Date: ${todayStr}

Choose an impactful topic from:
- "Why 2 Million Flutter Developers No Longer Need Node or Go: The Rise of Full-Stack Dart"
- "Inside the JetleafVM: How Pre-Warmed Isolates Deliver Sub-100ms Hot Reload for Backend Dart"
- "Enterprise Inversion of Control in Dart: Designing Spring-Style Pods Without Runtime Reflection Slowness"
- "Production Observability in Dart: Why Every Microservice Needs an Actuator"
- "Vibecoding Production Backends: Building Reliable Servers with AI Agents and Jetleaf MCP"
- "Comparing Dart Backend Solutions in 2026: Jetleaf vs Serverpod vs Dart Frog"

[ARTICLE STRUCTURE REQUIRED]
1. Headline & Sub-headline: Punchy, analytical, and authoritative.
2. Introduction & The Paradigm Shift: Why the industry is re-evaluating backend languages and the friction of multi-language stacks.
3. The Architectural Problem: What traditional backend frameworks get wrong, or why previous Dart backend attempts struggled.
4. The Jetleaf Solution & Deep Dive: Detailed breakdown with real, production-ready Dart code snippets (annotated controllers, Pod injection, or configuration DSL).
5. Benchmarks, Developer Experience & Performance: Explanation of the resident isolate architecture, compile-time AST scanning, and sub-second feedback loops.
6. The Enterprise Horizon: What production readiness means (health checks, actuator metrics, security, resilience).
7. Conclusion & Getting Started: Inspiring closing thoughts, quickstart commands (\`dart pub global activate jetleaf_tools && jl create my_api\`), and repository links.
`,

  'weekend-guide': (todayStr) => `
${SYSTEM_CONTEXT}

[YOUR TASK]
Create the "Full-Stack Dart Weekend Hack Guide" — a hands-on, high-impact tutorial showing developers how to build an end-to-end, real-world project in a single weekend using Jetleaf + Flutter.
Date: ${todayStr}

Focus on a compelling project idea (e.g. "Build a Real-Time Collaborative Task Board", "Build an AI-Powered Document Analyzer API", "Build a Multi-Tenant SaaS Billing Service with Stripe Webhooks").

[OUTPUT FORMAT REQUIRED]
Produce 3 ready-to-publish formats:
1. Format A: X (Twitter) Mega-Thread (Hook tweet with metrics/features, 7–10 step-by-step implementation tweets with code cards and architecture ASCII, CTA tweet linking to GitHub).
2. Format B: LinkedIn / Medium Step-by-Step Tutorial (Structured guide with prerequisites, Project Setup via \`jl create\`, Code Walkthrough for Controller/Service/Actuator, Flutter Client Connection, and Testing with \`jl test\`).
3. Format C: Reddit / Discord Community Announcement (Relatable developer post for \`r/FlutterDev\` and \`r/dartlang\` sharing the open-source repo, technical choices, and inviting contributors).
`
};

async function callGemini(modelName, prompt, apiKey) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Connection': 'close'
    },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
      }
    }),
    signal: AbortSignal.timeout(90000)
  });

  if (!response.ok) {
    const errorText = await response.text();
    const error = new Error(`Gemini API Error (${response.status}): ${errorText}`);
    error.status = response.status;
    throw error;
  }

  const data = await response.json();
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error('Gemini returned an empty candidate list or text.');
  }
  return text;
}

async function generateWithFallback(modelsToTry, prompt, apiKey) {
  let lastError = null;

  for (const model of modelsToTry) {
    for (let attempt = 1; attempt <= 2; attempt++) {
      try {
        console.log(`📡 Requesting generation using '${model}' (attempt ${attempt})...`);
        const result = await callGemini(model, prompt, apiKey);
        return { text: result, modelUsed: model };
      } catch (err) {
        lastError = err;
        const causeMsg = err.cause ? ` (cause: ${err.cause.message || err.cause.code || err.cause})` : '';
        console.warn(`⚠️ Attempt ${attempt} with '${model}' failed: ${err.message}${causeMsg}`);
        await new Promise(r => setTimeout(r, 2000));
      }
    }
    console.log(`🔄 Switching to next available fallback model...`);
  }

  throw lastError;
}

async function generateContent(type) {
  const promptFn = PROMPTS[type];
  if (!promptFn) {
    console.error(`Unknown content type: ${type}. Choose from: ${Object.keys(PROMPTS).join(', ')}`);
    process.exit(1);
  }

  const now = new Date();
  const dateStr = now.toISOString().split('T')[0];
  const dayOfWeek = now.toLocaleDateString('en-US', { weekday: 'long', timeZone: 'Africa/Lagos' });

  const candidateModels = await resolveCandidateModels(GEMINI_API_KEY, PREFERRED_MODEL);
  console.log(`🚀 Generating [${type}] for ${dayOfWeek}, ${dateStr}...`);

  const prompt = promptFn(dateStr, dayOfWeek);
  const { text: generatedText, modelUsed } = await generateWithFallback(candidateModels, prompt, GEMINI_API_KEY);
  console.log(`🎉 Generation succeeded using model: '${modelUsed}'`);

  let subDir = '';
  let filename = '';

  switch (type) {
    case 'daily-tips':
      subDir = 'daily-tips';
      filename = `${dateStr}.md`;
      break;
    case 'newsletter':
      subDir = 'newsletters';
      filename = `${dateStr}-newsletter.md`;
      break;
    case 'article':
      subDir = 'articles';
      filename = `${dateStr}-article.md`;
      break;
    case 'weekend-guide':
      subDir = 'weekend-guides';
      filename = `${dateStr}-weekend-guide.md`;
      break;
  }

  const outputDir = path.join(MARKETING_DIR, subDir);
  fs.mkdirSync(outputDir, { recursive: true });

  const filePath = path.join(outputDir, filename);
  fs.writeFileSync(filePath, generatedText.trim() + '\n', 'utf8');

  console.log(`✅ Successfully generated: ${filePath}`);
}

generateContent(targetType).catch(err => {
  const cause = err.cause ? ` (Cause: ${err.cause.message || err.cause})` : '';
  console.error(`❌ Generation failed: ${err.message}${cause}`);
  process.exit(1);
});
