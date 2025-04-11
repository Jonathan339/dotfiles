local M = {}
local defaults = require("plugins.lsp.defaults")
local lspconfig = require("lspconfig")

M.setup_lsp = function(server, config)
  lspconfig[server].setup(vim.tbl_deep_extend("force", {
    capabilities = defaults.capabilities,
    on_attach = defaults.on_attach,
    on_init = defaults.on_init,
  }, config))
end

function M.map(mode, lhs, rhs, opts)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_deep_extend("force", { silent = true, noremap = true }, opts or {}))
end

function M.create_buf_map(bufnr, opts)
  return function(mode, lhs, rhs, map_opts)
    M.map(mode, lhs, rhs, vim.tbl_deep_extend("force", { buffer = bufnr }, opts or {}, map_opts or {}))
  end
end

function M.merge_list(tbl1, tbl2)
  local seen = {}
  for _, v in ipairs(tbl1) do seen[v] = true end
  for _, v in ipairs(tbl2) do
    if not seen[v] then table.insert(tbl1, v) end
  end
  return tbl1
end

function M.merge(...) return vim.tbl_deep_extend("force", ...) end

function M.split(str, sep)
  local res = {}
  for w in str:gmatch("([^" .. sep .. "]*)") do
    if w ~= "" then table.insert(res, w) end
  end
  return res
end

function M.get_short_file_path(path)
  local dirs = {}
  for dir in string.gmatch(path, "([^/]+)") do table.insert(dirs, dir) end
  local n = #dirs
  return n > 3 and ("../" .. dirs[n - 2] .. "/" .. dirs[n - 1] .. "/" .. dirs[n]) or path
end

function M.get_short_cwd()
  local parts = vim.split(vim.fn.getcwd(), "/")
  return parts[#parts]
end

function M.diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  return gitsigns and { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed } or nil
end

function M.show_macro_recording()
  local reg = vim.fn.reg_recording()
  return reg == "" and "" or ("Recording @" .. reg)
end

return M
