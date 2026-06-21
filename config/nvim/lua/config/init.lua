local M = {}

-- Cacheamos funciones nativas para evitar Lookups repetidos en el bucle
local ipairs = ipairs
local pcall = pcall

---Cargador seguro con manejo de errores descriptivo
---@param module string Nombre del módulo a requerir
local function safe_require(module)
	local ok, err = pcall(require, module)
	if not ok then
		-- vim.schedule asegura que Neovim ya inicializó la UI de notificaciones
		-- evitando que el error rompa el renderizado de la pantalla de inicio
		vim.schedule(function()
			vim.notify("Error loading " .. module .. "\n\n" .. err, vim.log.levels.ERROR)
		end)
	end
end

---Iterador de módulos sobre una lista plana
---@param modules string[]
local function load_modules(modules)
	for i = 1, #modules do
		safe_require(modules[i])
	end
end

M.setup = function()
	-- 1. Módulos Core / Críticos (Se cargan secuencialmente en el microsegundo 0)
	load_modules({
		"config.option", -- Opciones nativas (importante el plural si renombraste a options.lua)
		"config.lazy",    -- Gestor de plugins Lazy.nvim
		"config.map",     -- Keymaps globales
	})

	-- 2. Módulos Secundarios / No Bloqueantes
	-- Se delegan al final del loop de eventos para acelerar el arranque visual
	vim.schedule(function()
		load_modules({
			"config.autocmd", -- Autocomandos, eventos y el runner de C/C++
		})
	end)
end

-- Ejecutamos la inicialización del ecosistema
M.setup()

return M
