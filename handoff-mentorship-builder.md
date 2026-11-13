# active-memory handoff: Mentorship Builder (drag-and-drop class planner)

**Handoff #1** · 2026-11-13 · Lineage: #1 (2026-11-13): built and published a stable v1 drag-and-drop mentorship builder with placeholder topics; received the real curriculum and offer details; on-brand simplification requested but not started.

## 0. Instructions for Claude (read first)

You are continuing work from a previous chat. That chat is gone; this file is the complete context and the source of truth.

1. Read this whole file before replying.
2. Follow sections 3 (Style), 4 (Hard rules) and 5 (Corrections) in every reply, for the rest of this chat. They override your defaults.
3. Use the values in section 8 exactly. Never round, re-estimate, or "correct" them.
4. Do not suggest anything listed in section 7 (Changed / rejected) again unless the user brings it up.
5. Code word: None active. If the user types /amcodeword, start every reply with the phrase they choose (default "Yes Boss!").
6. Your first reply: at most 5 lines covering the goal, the current state, and the next step (section 11). Mention any files from section 13 that were not attached. Ask the questions in section 12 if there are any. End with "Ready to continue with <next step>?" Then wait for the user's go.

## 1. Mission
- **Goal:** a custom HTML component, embedded later in Mario's website (place decided later), where prospective mentorship students pick topics, then drag puzzle-piece classes into their own 8-class or 12-class mentorship plan.
- **Done looks like:** a modern, fun builder with satisfying drag-and-drop "haptics" (the drop feels good), on brand with Mario's website, focused only on the builder itself.
- **Why it matters:** shortens the time between the discovery call and the start of the mentorship (they build it together on the call, then Mario sends payment details), which helps conversion; and standardizes content so each class is pre-made, one per module, with no prep per student.

## 2. About the user (as relevant to this work)
- Mario Leone (goes by Maroo): Lead Tech Artist at TriArts, Scene Assembly professor at Voxel School Madrid, Houdini Certified and Unreal Authorized Instructor. Education brand: NodeFlow.
- Offers 1:1 mentorships in Houdini and Unreal; about 15 mentorship students so far. Discovery calls booked through Calendly.
- Says he has a new website where people are already signing up (exact URL not given in chat).
- Mainly uses Claude for content and visuals; Python tools come later.
- The repo in this session (`MarioNodeFlow/MarioNodeFlow.github.io`) is a stock Jekyll Chirpy blog titled "NodeFlow Library". It is probably not the "new website".

## 3. Style & communication
- **Language:** English.
- **Tone:** direct and practical, no fluff.
- **Reply length:** short. He interrupts long runs and asks for status. Give quick status lines while working.
- **Formatting:** short paragraphs of 30 to 50 words, **bold keywords**, bullets only for checklists, no repetition, every line practical (Mario's stated preference in his socials skill).
- **Working style:** wants a **stable, working version first**, then iterations. Give a status when asked. Test before publishing.
- **Avoid:** long silent build runs; generic placeholder content once the real curriculum exists; marketing copy inside the builder artifact.

## 4. Hard rules (word for word)
1. "make it on brand like my website, simplify it"
2. "all the context like build your mentorship etc just give me a messge text in chat so i can manually add it to the website, the artifact must focus only on the mentorship builder"
3. "focus on the idea that these are based on studio workflows i have learned in my industry experience, we should emphasize that most ppl pre record smth and offer to you, with me you will have 2h per week to ask me questions and my personal whatsapp number to reach out every week." (This messaging goes in the chat text for the website, not in the artifact, per rule 2.)
4. "give me a stable version first" / "need a status"
5. From the first request: the drag and drop should do "a nice, dropping thing. So it feels modern, it feels fun, and people enjoy creating it."

## 5. Corrections log
| # | Claude did | The user wanted |
|---|---|---|
| 1 | Built with invented placeholder topics and classes (Solaris, USD, Copernicus, PDG, FX, Shading, Lighting, Environments, 5-7 classes each) | The real module list in section 8 |
| 2 | Started a big content rewrite mid-flight, leaving the page half-edited | "give me a stable version first", "need a status" |
| 3 | Put header copy, a "what you get" promise strip and a 3-step indicator inside the artifact | Artifact = only the builder; all context text given in chat for him to paste on the website |
| 4 | Used its own design (graphite, orange #ff8a3d, Unbounded/Manrope/JetBrains Mono) | On brand like his website |

## 6. Decisions
| Decision | Why |
|---|---|
| Classes are puzzle pieces dragged into a chain of slots; tap a piece also adds it to the next free slot | User's concept; tap covers mobile |
| One class = one week | 8 weeks (8 classes) or 12 weeks |
| 12 weeks = full program to get ready to work in the industry, with extra classes: portfolio production, website creation, personal branding | User's words: "main diff is full program to get you ready to work for the industry" |
| Modules come in 3 types: Houdini, Unreal, External software | User's call |
| Welcome module is mandatory if the student never opened the software, useful if they just started | User's words |
| Topics are not final; Mario will give corrections | "The topics are not important… I will give you correction on that" |

## 7. Changed / rejected
- Placeholder topics → real curriculum in section 8 (user supplied the list).
- Header, intro copy, promise strip, steps indicator inside the artifact → removed from the artifact; deliver as chat text instead (rule 2).
- Claude's own visual style → Mario's brand (section 8).
- Three-layout "Prototype" switcher (Workbench / Toolbox / Timeline): built for testing because the user said "Let's try some layouts first". Not rejected yet, but "simplify it" suggests dropping it. Confirm (section 12).

## 8. Data & facts (exact)

**Curriculum (user's words, typos fixed only where obvious):**

| Type | Module | Description (user's text) |
|---|---|---|
| Houdini | Welcome | "add this module if you need a software quick start, mandatory if you never opened the software useful if you just started. ui, attributes classes and kinds, variables, params, contexts, license types and houdini education infrastructure" |
| Houdini | Copernicus I | "intro to copernicus its role from main nodes to a full material through multiple techniques, intro but practical hands on, you will be creating your first materials." |
| Houdini | Copernicus II | "learning using cops on terrains (hou22) compositing in copernicus, and more advanced material workflows" |
| Houdini | Solaris I | "intro to usd, solaris, main panels, best production workflows" |
| Houdini | Solaris II | "matx shading in usd from primvars, to material randomization" |
| Houdini | Solaris III | "lighting vs shadows control, and rendering with karma xpu" |
| Houdini | Particles I | "intro to fx and particles, main concepts, from a simple particle system to ABSTRACT structures created by particles." |
| Houdini | Particles II | "xxx" (to come) |
| Houdini | Particles III | "xxx" (to come) |
| Houdini | Vellum I | "intro to vellum, understanding constraints simulate cloth, hairs etc" |
| Houdini | Vellum II | "learning how to break constraints and production workflows to not alter topology" |
| Houdini | Vellum III | "vellum grains and fluids, use cases and..." (unfinished) |
| Houdini | Vex I, Vex II, Vex III | no description yet |
| Houdini | Procedural modeling I, II, III | no description yet |
| Unreal | welcome class | no description yet |
| External software | (none listed yet) | |
| 12-week extras | Portfolio production, Website creation, Personal branding | only in the 12-week program |

**Offer messaging (for the website text, not the artifact):**
- Classes are based on studio workflows Mario learned in his industry experience.
- Most people pre-record something and offer it to you.
- With Mario: 2h per week to ask him questions.
- His personal WhatsApp number to reach out every week.
- Flow: build the plan together on the call → Mario sends payment details → start.

**Brand (from Mario's socials skill; confirm it matches the website):**
- Orange **#FF6A1D**, one accent only, on near-black **#0b0b0c**. Light grey text **#8f8f96**, off-white **#f2f0ec**.
- Brand font **Archivo**. Geist + Geist Mono for carousels and email. JetBrains Mono labels in reel graphics. Dark grid background in reel graphics.
- Brand associations: professional, clean, modern, confident, bold.
- Logo draft: "ML" monogram + wordmark **Mario** (bold) **Leone** (light), dot of the i in orange.

**Tech facts:**
- Builder is a single self-contained HTML file. Pointer-events drag engine (mouse, pen, touch long-press about 180 ms), ghost piece with velocity tilt, magnet pull toward hovered slot, width morph to slot, spring landing, squash, ring pulse, sparks, neighbour nudge, WebAudio click sounds with a mute toggle, `navigator.vibrate`, full-chain celebration, FLIP reordering, swap and replace, drag out to remove, undo toasts, 8/12 size switch.
- On submit it fires `CustomEvent('mentorship:submit', {detail: planData()})` on the root, for wiring to the site later.
- Bug fixed: hidden summary sheet blocked all clicks in a plain browser; fix = `.mb [hidden]{display:none!important}`.
- Test (Playwright, 1280 px and 390 px): drag into slot 3 OK, tap-add OK (5 filled, "3 classes to go"), no horizontal overflow on mobile (scrollWidth 390), no JS errors.

## 9. People, terms & names
- **People:** Mario Leone (user, the mentor).
- **Terms:** "module" / "class" = one pre-made class, one per week. "PTG" in the user's voice message = PDG (Houdini TOPs). "matx" = MaterialX. "cops" = Copernicus. "hou22" = Houdini 22.
- **Names in use:** artifact title "Mentorship Builder"; artifact URL https://claude.ai/artifact/EG8a6MYVpnceDfR1ny3EiG (private, version 2, labelled "v1.1 stable, tested"); file `mentorship-builder.html`; dev branch `claude/amazing-fermi-w3zhz4` in repo `MarioNodeFlow/MarioNodeFlow.github.io` (nothing committed yet).

## 10. Work state
| Item | Status | Version / location | Notes |
|---|---|---|---|
| Builder v1.1 (placeholder topics, own styling) | stable, tested, published | https://claude.ai/artifact/EG8a6MYVpnceDfR1ny3EiG · `mentorship-builder.html` in the repo folder (uncommitted) | Still contains header copy, promise strip and steps; must be stripped |
| Real curriculum in the builder | not started | | Data in section 8 |
| On-brand restyle + simplify | not started | | Rules 1-2 |
| Website text (intro + offer message) for Mario to paste | not started | | Goes in chat, not the artifact |
| Embedding in the website | not started | | Location decided later |

## 11. Next steps
1. **Next action:** rebuild the artifact as builder-only: remove header, promise strip, steps and prototype bar; restyle to the brand (#0b0b0c, #FF6A1D, #f2f0ec, #8f8f96, Archivo); keep the drag-and-drop feel; load the real curriculum from section 8 grouped Houdini / Unreal / External software; 8 weeks vs 12 weeks with the 3 industry extras unlocked only at 12; Welcome pinned to week 1 if the student has never opened the software.
2. Test once in Playwright, republish to the same artifact URL.
3. Give Mario the website text in chat: headline, intro and the offer message (studio workflows, not pre-recorded, 2h per week, personal WhatsApp every week, plan together on the call then payment details).
4. Ask him for the missing descriptions (Particles II/III, Vellum III end, VEX I-III, Procedural modeling I-III, Unreal welcome, External software modules).

## 12. Open questions ⚠️
- Which website is "my website" for the brand look? Candidates: the Kit page (https://mario-leone.kit.com/0d00a33b1f), https://nodeflowhub.super.site/, or another new site. If unknown, use the brand values in section 8.
- Keep one layout only after "simplify it"? Candidates: Workbench (topics | classes | plan) or Timeline (stacked). Or keep the switcher.
- Should the Welcome question ("have you used Houdini/Unreal before?") be part of the builder, or decided on the call?
- Can Part II/III be picked without Part I? Suggestion only: allow it with a soft hint.
- External software: which programs?

## 13. Re-attach checklist
- [ ] `mentorship-builder.html` (in the repo folder, or read the artifact URL above): current v1.1 code to strip and restyle instead of starting from zero.
- [ ] The website URL or a screenshot of it: to match the brand.

---
<sub>Audit: 13/13 sections · 5 rules · 4 corrections · 30 data points · secrets removed: none found · generated by active-memory</sub>
