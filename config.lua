require "setup"()

function LspCapabilities()
  local _, c = next(vim.lsp.buf_get_clients())
  print(vim.inspect(c.resolved_capabilities))
end

-- Synchronously organise imports, courtesy of
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
-- https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
function OrgImports(ms)
  ms = ms or 1000
  local context = {source = {organizeImports = true}}
  local params = vim.lsp.util.make_range_params()
  params.context = context

  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params,
                                          ms)
  for _, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        vim.lsp.util.apply_workspace_edit(r.edit)
      else
        vim.lsp.buf.execute_command(r.command)
      end
    end
  end
end

-- inspired by https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
function SmartTabComplete()
  local s = vim.fn.getline("."):sub(1, vim.fn.col(".") - 1):gsub("%s+", "")

  if s == "" then return "	" end
  if s:sub(s:len(), s:len()) == "/" then return "" end
  return ""
end
