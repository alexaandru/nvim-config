-- luacheck: globals vim
local function each(cmd)
  return function(...)
    local args = vim.tbl_flatten({...})
    for _, v in ipairs(args) do vim.cmd(cmd .. " " .. v) end
  end
end

local util = {
  pa = each "pa",
  se = each "se", -- TODO: https://github.com/neovim/neovim/pull/13479
  hi = each "hi!", -- TODO: https://github.com/neovim/neovim/issues/9876
  sig = each "sig define", -- ^^^
  com = each "com!", -- TODO: https://github.com/neovim/neovim/pull/11613
  colo = each "colo",
  notify_beautify = require "notify",
  save_hooks = {},
}

local wait_default = 1200

function util.Format(wait_ms)
  vim.lsp.buf.formatting_sync(nil, wait_ms)
end

-- Synchronously organise imports, courtesy of
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
-- https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
function util.OrgImports(wait_ms)
  local params = vim.lsp.util.make_range_params()
  params.context = {source = {organizeImports = true}}
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, wait_ms)
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

function util.BufWritePre(wait_ms)
  local hooks = util.save_hooks[vim.api.nvim_win_get_buf(0)]
  if not hooks then return end

  for k in pairs(hooks) do util[k](wait_ms or wait_default) end
  vim.cmd("up!")
end

-- inspired by https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
function util.SmartTabComplete()
  local s = vim.fn.getline("."):sub(1, vim.fn.col(".") - 1):gsub("%s+", "")
  local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
  end

  if s == "" then return t "<Tab>" end
  if s:sub(s:len(), s:len()) == "/" then return t "<C-x><C-f>" end

  return t "<C-x><C-o>"
end

local cfg_files = (function()
  local pat = "*.lua"
  local c = vim.fn.stdpath("config")
  local x = function(v)
    return string.sub(v, #c + 2)
  end

  return vim.tbl_map(x, vim.fn.glob(c .. "/" .. pat, 0, 1))
end)()

function util.CfgComplete(argLead)
  local fn = function(v)
    return argLead == "" or vim.startswith(v, argLead)
  end

  return vim.tbl_filter(fn, cfg_files)
end

function util.GitStatus()
  local branch = vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD 2> /dev/null"))
  if branch == "" then return end
  local dirty = vim.fn.system("git diff --quiet || echo -n \\*")
                    .. vim.fn.system("git diff --cached --quiet || echo -n \\+")
  vim.w.git_status = branch .. dirty
end

function util.ProjRelativePath()
  return string.sub(vim.fn.expand("%:p"), #vim.w.proj_root + 1)
end

function util.LspCapabilities()
  local cap = {}
  for _, c in pairs(vim.lsp.buf_get_clients()) do cap[c.name] = c.resolved_capabilities end
  print(vim.inspect(cap))
end

function util.unpack(...)
  local arg = vim.tbl_flatten {...}
  local what = {}
  for _, v in ipairs(arg) do table.insert(what, util[v]) end
  return unpack(what)
end

function util.unpack_G(...)
  local arg = vim.tbl_flatten {...}
  for _, v in ipairs(arg) do _G[v] = util[v] end
end

function util.so(s)
  vim.cmd(("so %s/%s"):format(vim.fn.stdpath("config"), s))
end

-- TODO: https://github.com/neovim/neovim/pull/12378
function util.au(...)
  for name, au in pairs(...) do
    vim.cmd(("aug %s | au!"):format(name))
    each("au")(au)
    vim.cmd "aug END"
  end
end

function util.map(mappings)
  for mode, mx in pairs(mappings) do
    for _, m in ipairs(mx) do
      local lhs, rhs, opts = unpack(m)
      opts = opts or {}
      opts.noremap = true
      vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
    end
  end
end

function util.disable_providers(px)
  local fn = function(p)
    vim.g["loaded_" .. p .. "_provider"] = 0
  end
  vim.tbl_map(fn, px)
end

function util.exec(cmd, ret)
  vim.api.nvim_exec(cmd, ret ~= nil and ret)
end

function util.let(cfg)
  for group, vars in pairs(cfg) do
    for k, v in pairs(vars) do
      if type(v) == "table" then
        for kk, vv in pairs(v) do vim[group][k .. "_" .. kk] = vv end
      else
        vim[group][k] = v
      end
    end
  end
end

return util
