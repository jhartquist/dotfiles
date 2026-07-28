# nvim

Single-file config (`init.lua`) for nvim 0.12+. No plugin manager, no mason:

- **Plugins** — built-in `vim.pack`, declared at the top of `init.lua`.
  Missing ones are cloned automatically on startup.
- **LSP servers & formatters** — installed by nix (`home.nix`), so they're
  declarative and on PATH. `sourcekit-lsp` comes with Xcode.
- **LSP wiring** — native `vim.lsp.enable`; nvim-lspconfig is only along for
  its per-server defaults (cmd, root markers), none of its API.

## First launch

Needs network: `vim.pack` clones the plugins, then treesitter compiles its
parsers async. Restart once after it settles.

## Maintenance

| task | how |
|---|---|
| update plugins | `:lua vim.pack.update()` |
| add a plugin | add to the `vim.pack.add` list, restart |
| add a language | server → `home.nix` + `vim.lsp.enable` list; parser → `parsers` list; formatter → `home.nix` + `formatters_by_ft` |
| inspect LSP | `:checkhealth vim.lsp` |

## Keymaps (leader = space)

| keys | action |
|---|---|
| `<leader>f` / `g` / `b` / `r` | files / live grep / buffers / resume (fzf-lua) |
| `-` | file browser (oil — edit dirs like buffers, `:w` applies) |
| `gd`, `K` | definition, hover |
| `grn`, `gra`, `grr`, `gri`, `gO` | rename, code action, references, implementation, symbols (0.11+ builtins) |
| `<leader>d` | diagnostic float |
| `<leader>h` | clear search highlight |

Formatting runs on save (conform; falls back to LSP).
