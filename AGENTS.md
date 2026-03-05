# AGENTS.md

Guidelines for AI coding agents (Codex)

- Combat systems must be server-authoritative.
- Client scripts handle input, animation, and visual effects only.
- Server validates hits, cooldowns, and damage.
- All combat configs go in ReplicatedStorage/Combat/Config.lua.
- Use modular scripts instead of large monolithic scripts.
- Include comments explaining major systems.