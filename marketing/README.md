# Jetleaf Marketing Engine 🚀

Automated developer advocacy and content generation engine for **Jetleaf** (jetleaf.hapnium.com | [github.com/hapnium/jetleaf](https://github.com/hapnium/jetleaf)). 

It autonomously generates on-brand, high-converting social media carousels, weekly developer newsletters ("The Full-Stack Dart Dispatch"), technical thought-leadership essays for Substack/Medium/LinkedIn, and weekend hack guides using Google's Gemini API.

---

## 📂 Directory Structure

```text
marketing/
├── generator.mjs            # Standalone zero-dependency Node.js generator script
├── daily-tips/              # Daily 6-slide social carousels, Canva/Figma specs & captions
├── newsletters/             # Weekly Sunday newsletters for Monday developer dispatch
├── articles/                # In-depth Substack / LinkedIn / dev.to thought leadership essays
├── weekend-guides/          # Thursday weekend hack guides (X thread, LinkedIn, Reddit)
└── README.md
```

---

## ⚙️ How it Runs 24/7 (GitHub Actions)

The workflow at `.github/workflows/marketing-engine.yml` runs in GitHub's cloud on schedule **even if your laptop is closed or turned off**:

| Task | Cron (UTC) | Local Time (Africa/Lagos) | Destination | Core Focus |
|---|---|---|---|---|
| **Daily Social Tips** | `0 7 * * *` | Everyday at **8:00 AM** | `marketing/daily-tips/` | Rotating weekday Jetleaf themes (IoC, Web, VM, Actuator, Full-Stack, AI, Data/Security) |
| **Weekly Newsletter** | `0 9 * * 0` | Every Sunday at **10:00 AM** | `marketing/newsletters/` | "The Full-Stack Dart Dispatch" weekly edition |
| **Weekly Technical Essay** | `0 8 * * 3` | Every Wednesday at **9:00 AM** | `marketing/articles/` | Long-form technical essays (1,400–1,800 words) |
| **Weekend Hack Guide** | `0 14 * * 4` | Every Thursday at **3:00 PM** | `marketing/weekend-guides/` | Step-by-step project guides (X thread, LinkedIn, Reddit) |

When triggered, it calls Gemini, generates the structured markdown content, and automatically commits it back to this repository.

---

## 🔑 One-Time Setup: Add your Gemini API Key to GitHub

1. Open your GitHub repository in your browser: `github.com/hapnium/jetleaf`.
2. Go to **Settings** > **Secrets and variables** > **Actions**.
3. Click **New repository secret**.
4. Name: `GEMINI_API_KEY`
5. Value: *Paste your Google Gemini API key*
6. Click **Add secret**.

That's it! GitHub Actions will now run the engine automatically on schedule.

---

## 💻 Manual Testing (Local Machine)

You can also run the generator manually from your terminal anytime:

```bash
# 1. Generate Daily Tip (Rotating by day of week)
GEMINI_API_KEY="your-api-key" node marketing/generator.mjs daily-tips

# 2. Generate Weekly Newsletter
GEMINI_API_KEY="your-api-key" node marketing/generator.mjs newsletter

# 3. Generate Weekly Thought-Leadership Article
GEMINI_API_KEY="your-api-key" node marketing/generator.mjs article

# 4. Generate Weekend Project Hack Guide
GEMINI_API_KEY="your-api-key" node marketing/generator.mjs weekend-guide
```

---

## 🖱️ Manual Trigger via GitHub UI

You can generate any content piece on demand without touching code:
1. Go to the **Actions** tab on your GitHub repository.
2. Select **Jetleaf Marketing Engine** from the left-hand workflow list.
3. Click **Run workflow**, select the content type from the dropdown, and click the green button.
