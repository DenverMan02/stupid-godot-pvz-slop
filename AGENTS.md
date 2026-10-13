# AGENTS.md

## Project overview

- This is an early-stage Plants vs. Zombies-inspired semi-MMO project built with **Godot 4.7 and GDScript**.
- The project is configured for a 1920×1080 viewport and Godot's Mobile renderer. Keep the intended desktop/mobile targets in mind.
- The current XFL example is `Assets/Plants/peashooter.xfl/`. It contains Adobe Animate XFL data such as `DOMDocument.xml`, `data.json`, and the `library/` assets and timelines.
- The project is still early-stage. Inspect the current repository before assuming a renderer, importer, gameplay loop, or networking system already exists.

## Current AI tools

These are the AI tools currently used on the project:

- **Google AI Studio** — coding, experimentation, and implementation iteration.
- **ChatGPT** — architecture discussions, planning, debugging, reviewing changes, and documenting decisions.
- **Google Jules** — delegated coding and implementation tasks.

These are useful defaults, not exclusive assignments. Follow the project owner's instructions for the task at hand, and keep important decisions and completed changes in the repository so the different tools can work from the same source of truth.

## Highest-priority technical requirement: XFL performance

The game must support **hundreds of simultaneously active XFL animation instances** without unacceptable performance loss. Make scalability a design constraint from the beginning; do not build a simple implementation that assumes only a handful of plants will be on screen.

### XFL source and import pipeline

- Treat the committed XFL exports as the authoritative source for their visual animation data. Preserve source timelines and library assets unless a task explicitly calls for changing them.
- The project uses an XFL-first approach to avoid reverse-engineering PAM binaries. Do not start a PAM parser or fall back to PAM-specific implementation without identifying a concrete limitation in the XFL export.
- Prefer an import/build step that parses XFL data and prepares runtime-ready resources. **Do not parse XML, rediscover symbols, or resolve asset paths every frame.**
- Cache and share immutable animation definitions, texture resources, and precomputed data across instances. Keep per-instance playback state separate from shared source data.
- Preserve animation fidelity: nested symbols, timeline/keyframe timing, transforms, pivots/registration points, visibility/alpha, frame labels, looping, and relevant color/blend behavior. Verify which of these features occur in actual assets rather than assuming every feature is used.
- Keep visual animation separate from gameplay logic. Attacks, projectile creation, damage, plantfood effects, and other gameplay behavior must be triggered through explicit gameplay/event logic, not inferred from incidental rendering details.
- Avoid creating a full Godot scene-node hierarchy for every nested timeline symbol unless profiling demonstrates that it is acceptable. Evaluate a compact/custom-draw or batched rendering path, but prioritize correctness and measured results over assumptions.
- Reuse textures and consider atlasing where it improves real batching and memory use. Do not merge or reorder layers in ways that break depth, masks, transforms, or animation fidelity.
- Never do avoidable allocations, repeated resource lookups, or expensive parsing in per-frame/per-instance hot paths.

### Performance verification

- Stress-test with **100, 250, and 500 concurrent instances** as the renderer becomes usable.
- Test more than static idle sprites: include nested symbols, different animation states, frame changes, and representative effects.
- Measure frame time/FPS, CPU and GPU time where available, draw calls/batching, and memory. A 60 FPS target allows about 16.7 ms per frame, but meeting it must be verified on actual target hardware.
- Test on a lower-end target device as well as the development machine when possible. Record the test setup and results; do not claim performance targets are met without measurements.
- If optimizations change output, compare against the source animation in Adobe Animate or another trusted reference before accepting them.

## Coding and repository practices

- Read the relevant scripts, scenes, configuration, and asset structure before making changes. Check the current diff and preserve unrelated user work.
- Use Godot 4.7-compatible GDScript and APIs. Avoid introducing external dependencies unless the project owner approves them.
- Keep code modular: separate XFL import/parsing, runtime animation data, playback state, rendering, and gameplay behavior when those responsibilities are introduced.
- Prefer clear names, explicit types where useful, and comments that explain non-obvious compatibility or performance decisions.
- Avoid unrelated changes to the existing title screen, audio, fonts, logo, theme, and Git helper when working on the renderer.
- Do not commit credentials, API keys, tokens, or local environment files. Do not force-push or rewrite shared history.
- Keep generated Godot cache files out of commits. Follow the repository's Git LFS configuration for audio assets.
- Run the most relevant available checks after changes (for example, a headless Godot project check and focused importer/renderer tests). Be explicit about any checks that could not be run; never report unrun tests as passing.
- Do not commit or push changes unless the project owner explicitly asks for it.

## Working approach

1. Inspect the existing implementation and identify the smallest useful change.
2. Preserve XFL source data and make runtime resources reproducible from it.
3. Implement correctness first, then profile before optimizing.
4. Add a focused test or reproducible manual test for new behavior.
5. Summarize changed files, validation performed, known limitations, and any decisions the next AI/tool needs to know.
