local M = {}

local defaults = {
	ensure_installed = {},
	skip_fts = {
		"gitcommit",
		"gitrebase",
		"help",
		"TelescopePrompt",
		"neo-tree",
		"oil",
		"dirvish",
		"alpha",
		"startify",
		"qf",
	},
	max_file_size = 1024 * 1024,
	log_level = vim.log.levels.INFO,
	formatters = nil,
}

local state = {
	opts = nil,
	visited = {},
	queue = {},
	running = false,
	format_enabled = true,
}

local function log(msg, level)
	level = level or state.opts.log_level
	vim.schedule(function()
		pcall(vim.notify, "[auto-ensure] " .. msg, level)
	end)
end

local function contains(val, list)
	for _, v in ipairs(list) do
		if v == val then
			return true
		end
	end
	return false
end

local function process_queue()
	if state.running then
		return
	end
	state.running = true

	local function next()
		local job = table.remove(state.queue, 1)
		if not job then
			state.running = false
			return
		end
		job(function()
			vim.schedule(next)
		end)
	end
	vim.schedule(next)
end

local function enqueue(fn)
	table.insert(state.queue, fn)
	process_queue()
end

local function install_package(pkg_name, done)
	local ok, registry = pcall(require, "mason-registry")
	if not ok then
		log("mason-registry unavailable", vim.log.levels.WARN)
		if done then
			done()
		end
		return
	end

	local ok_pkg, pkg = pcall(registry.get_package, pkg_name)
	if not ok_pkg then
		log("unknown package: " .. tostring(pkg_name), vim.log.levels.WARN)
		if done then
			done()
		end
		return
	end

	if pkg:is_installed() then
		if done then
			done()
		end
		return
	end

	local handled = false
	local function on_done()
		if handled then
			return
		end
		handled = true
		if done then
			done()
		end
	end

	pkg:once("install:success", on_done)
	pkg:once("install:failed", function()
		log("install failed: " .. pkg_name, vim.log.levels.ERROR)
		on_done()
	end)
	pkg:install()
end

local function ensure_ft(ft)
	local tools = state.opts.ensure_installed[ft]
	if not tools then
		return
	end

	for _, name in ipairs(tools) do
		enqueue(function(next)
			install_package(name, next)
		end)
	end
end

local function should_skip(ft, buf)
	if not ft or ft == "" then
		return true
	end
	if contains(ft, state.opts.skip_fts) then
		return true
	end

	local max_size = state.opts.max_file_size
	if max_size and max_size > 0 then
		local name = vim.api.nvim_buf_get_name(buf)
		if name and name ~= "" then
			local ok, st = pcall((vim.uv or vim.loop).fs_stat, name)
			if ok and st and st.size and st.size > max_size then
				log(("skip (%.1f KB): %s"):format(st.size / 1024, ft), vim.log.levels.DEBUG)
				return true
			end
		end
	end

	return false
end

local function setup_formatting(fmt_opts)
	if not fmt_opts or not fmt_opts.formatters_by_ft then
		return
	end

	local ok, conform = pcall(require, "conform")
	if not ok then
		log("conform.nvim not available, skipping format setup", vim.log.levels.WARN)
		return false
	end

	local fmt_cfg = vim.tbl_deep_extend("force", {
		notify_on_error = false,
		format_on_save = false,
		default_format_opts = {
			lsp_format = "fallback",
			timeout_ms = 1000,
		},
	}, fmt_opts)

	conform.setup(fmt_cfg)

	local max_size = fmt_opts.max_format_size or 200 * 1024

	local function safe_format(bufnr)
		local name = vim.api.nvim_buf_get_name(bufnr)
		if name == "" then
			return
		end
		local ok_st, st = pcall((vim.uv or vim.loop).fs_stat, name)
		if ok_st and st and st.size and st.size > max_size then
			return
		end

		conform.format({
			bufnr = bufnr,
			lsp_fallback = fmt_cfg.default_format_opts.lsp_format == "fallback",
			quiet = true,
			timeout_ms = fmt_cfg.default_format_opts.timeout_ms or 1000,
		})
	end

	local fmt_aug = vim.api.nvim_create_augroup("AutoEnsureFormat", { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = fmt_aug,
		callback = function(args)
			if not state.format_enabled then
				return
			end
			safe_format(args.buf)
		end,
	})

	vim.api.nvim_create_user_command("Format", function()
		safe_format(vim.api.nvim_get_current_buf())
	end, {})

	vim.api.nvim_create_user_command("FormatToggle", function()
		state.format_enabled = not state.format_enabled
		vim.notify("Format on Save: " .. (state.format_enabled and "ON" or "OFF"))
	end, {})

	return true
end

function M.setup(opts)
	state.opts = vim.tbl_deep_extend("force", {}, defaults, opts or {})

	if state.opts.formatters then
		setup_formatting(state.opts.formatters)
	end

	local aug = vim.api.nvim_create_augroup("AutoEnsure", { clear = true })
	vim.api.nvim_create_autocmd("FileType", {
		group = aug,
		callback = function(args)
			local ft = vim.bo[args.buf].filetype
			if should_skip(ft, args.buf) then
				return
			end
			if state.visited[ft] then
				return
			end
			state.visited[ft] = true
			ensure_ft(ft)
		end,
	})

	vim.api.nvim_create_user_command("AutoEnsureHere", function()
		local buf = vim.api.nvim_get_current_buf()
		local ft = vim.bo[buf].filetype
		if should_skip(ft, buf) then
			log("skip: " .. tostring(ft), vim.log.levels.WARN)
			return
		end
		state.visited[ft] = nil
		ensure_ft(ft)
		log("re-ran ensure for: " .. ft, vim.log.levels.INFO)
	end, {})

	vim.api.nvim_create_user_command("AutoEnsurePurgeVisited", function()
		state.visited = {}
		log("visited cache cleared", vim.log.levels.INFO)
	end, {})

	vim.api.nvim_create_user_command("AutoEnsureAllKnown", function()
		for ft, _ in pairs(state.opts.ensure_installed) do
			if not contains(ft, state.opts.skip_fts) then
				state.visited[ft] = nil
				ensure_ft(ft)
			end
		end
		log("queueing installs for all known filetypes", vim.log.levels.INFO)
	end, {})
end

return M
