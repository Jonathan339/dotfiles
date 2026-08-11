local M = {}

local icons = {
  Error = '',
  Warning = '',
  Info = '',
  Hint = '',
  Debug = '',
  Circle = '●',

  Git = '',
  Add = '',
  Modified = '',
  Modified_alt = '',
  Remove = '',
  Rename = '',
  Unmerged = '',
  Untracked = '',
  Staged = '',
  Unstaged = '',
  Ignore = '',
  Conflict = '',
  Branch = '',
  Diff = '',
  Repo = '',
}

M.icons = {
  DEBUG = icons.Debug,
  ERROR = icons.Error,
  INFO = icons.Info,
  TRACE = '✎',
  WARN = icons.Warning,
}

function M.get(category)
  if category == 'git' then
    return {
      Add = icons.Add,
      Branch = icons.Branch,
      Diff = icons.Diff,
      Git = icons.Git,
      Ignore = icons.Ignore,
      Modified = icons.Modified,
      Modified_alt = icons.Modified_alt,
      Remove = icons.Remove,
      Rename = icons.Rename,
      Repo = icons.Repo,
      Unmerged = icons.Unmerged,
      Untracked = icons.Untracked,
      Unstaged = icons.Unstaged,
      Staged = icons.Staged,
      Conflict = icons.Conflict,
    }
  elseif category == 'diagnostics' then
    return {
      Debug = icons.Debug,
      Circle = icons.Circle,
      Error = icons.Error,
      Warning = icons.Warning,
      Information = icons.Info,
      Hint = icons.Hint,
    }
  end
  return {}
end

return M
