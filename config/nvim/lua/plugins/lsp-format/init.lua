return {
  "lukas-reineke/lsp-format.nvim",

  config = function()
    require("lsp-format").setup {
      -- Permitir deshabilitar el formateo para servidores específicos
      exclude = { "tsserver", "eslint" },

      -- Opciones de sincronización de formateo
      sync = true, -- Si deseas que sea sincrónico (bloquea el editor hasta que termine)

      -- Forzar el formateo aunque el buffer haya cambiado después de iniciar el formato
      force = true, -- Escribir cambios incluso si el buffer ha cambiado

      -- Configurar orden de formateo (puedes especificar servidores en orden)
      order = { "prettier", "eslint" }, -- Orden de ejecución de servidores de formateo

      -- Otras configuraciones personalizadas por servidor
      typescript = {
        tab_width = 2 -- Configuración de tipo de tabulador para TypeScript
      },
      yaml = {
        tab_width = 2 -- Configuración de tipo de tabulador para YAML
      },
    }
  end
}
