# Neovim config

Requires `nightly`.

- 100% [Fennel](https://fennel-lang.org) based, using my own, "nano" [Fennel shim](https://github.com/alexaandru/fennel-nvim);
- using the [builtin package manager](https://neovim.io/doc/user/pack.html#vim.pack) with added
  support for `after` & `build` hooks as well as support for lazily
  loading configs (so they can reference the package they
  are configuring, i.e. **gitsigns**);
- **syntax highlighting** (+ **code folding**, **context**, ~~incremental selection~~, **text objects**)
  powered by latest (@main) [TreeSitter];
- **AI ready**: **Copilot** via **LSP** (`npm install --global @github/copilot-language-server`) + [inline completion](https://neovim.io/doc/user/lsp.html#lsp-inline_completion)
  and **next edit suggestions** from [Sidekick.nvim](https://github.com/folke/sidekick.nvim);
- builtin [LSP](https://neovim.io/doc/user/lsp.html) setup for a 20+ grammars, of which I mainly use **Go**,
  **JavaScript**, **Terraform** and **Fennel**; configs copied from [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig);
- multi **LSP** setup: always **Copilot** then various LSP and/or 'formatprg' combinations:
  `tsserver` for **JS**, but `prettier` for formatting;
  `gopls` for **Go**, but I also `golangci-lint-ls`, etc.;
- **autoformat** wherever possible, either via **LSP** or via `'formatprg'`,
  plus **organize imports** for **Go** and **JS**;
- builtin "fuzzy" searching (`set path=",**"` and just use `:find whatever<Tab>` for filenames or `:Grep *whatever*`
  (set to `git grep`) for content);
- **custom picker** for files, buffers, LSP (workspace) symbols and diagnostics,
  that uses `'findfunc'` and the builtin `fuzzy-matching`; with multiple select;
- custom **live grep**;
- **git** integration via [gitsigns](https://github.com/lewis6991/gitsigns.nvim): despite the misleading name it packs quite a lot of power!;
- persistent terminal toggled via `<C-Enter>` (`:ToggleTerm`) starts in the current file's folder;
  `:Term` available for spawning additional terminal instances;
- minimal UI (no statusbar/linenumber; git branch, filename and status in titlebar);
- custom `ui.input` and `ui.select`.
