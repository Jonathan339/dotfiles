local M = {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
        select = {
            get_config = function(opts)
                if opts.kind == "codeaction" then
                    return {
                        backend = "nui",
                        nui = {relative = "cursor", max_width = 40}
                    }
                end
            end
        },
        input = {win_options = {winhighlight = "NormalFloat:DiagnosticError"}}
    }
}
M.config = function(opts) require("dressing").setup(opts) end

return M
