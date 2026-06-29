local function map(mode, lhs, rhs, opts)
  local default_opts = {
    desc = "",
    noremap = true,
    silent = true,
  }

  if opts then
    for k, v in pairs(opts) do
      default_opts[k] = v
    end
  end

  vim.keymap.set(mode, lhs, rhs, default_opts)
end

return { map = map }