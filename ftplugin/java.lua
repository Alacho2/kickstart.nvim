-- ftplugin/java.lua

-- 1. Standard Vim Options for Java
vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4
vim.opt_local.softtabstop = 4

local status, result = pcall(function()
  local jdtls = require 'jdtls'
  local home = os.getenv 'HOME'

  -- =======================================================================
  -- 2. JAVA PATHS (Updated from SDKMAN)
  -- =======================================================================

  -- Use `home` variable for portability.
  -- NOTE: Ensure these specific versions exist in your `sdk list java`
  local java_17_home = home .. '/.sdkman/candidates/java/17.0.18-tem'
  local java_21_home = home .. '/.sdkman/candidates/java/21.0.9-tem'

  -- =======================================================================
  -- 3. MASON PATHS & BUNDLES
  -- =======================================================================

  -- Bypass Mason Registry and look directly in the data directory
  local mason_packages = vim.fn.stdpath 'data' .. '/mason/packages'

  local function get_package_path(package)
    local path = mason_packages .. '/' .. package
    if vim.fn.isdirectory(path) ~= 1 then
      -- Warn nicely instead of crashing the whole script
      vim.notify('Mason package not found: ' .. package, vim.log.levels.WARN)
      return nil
    end
    return path
  end

  local jdtls_path = get_package_path 'jdtls'
  if not jdtls_path then
    return
  end -- specific exit if core jdtls missing

  local debug_path = get_package_path 'java-debug-adapter'
  local test_path = get_package_path 'java-test'

  -- Determine OS for config path
  local os_config = 'linux'
  if vim.fn.has 'mac' == 1 then
    os_config = 'mac'
  end
  local config_path = jdtls_path .. '/config_' .. os_config

  local launcher_jar = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')
  if launcher_jar == '' then
    error('Could not find launcher jar in: ' .. jdtls_path .. '/plugins/')
  end

  -- Load Debug and Test bundles if they exist
  local bundles = {}
  if debug_path and vim.fn.isdirectory(debug_path) == 1 then
    vim.list_extend(bundles, vim.split(vim.fn.glob(debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', 1), '\n'))
  end
  if test_path and vim.fn.isdirectory(test_path) == 1 then
    vim.list_extend(bundles, vim.split(vim.fn.glob(test_path .. '/extension/server/*.jar', 1), '\n'))
  end

  -- FIX: Added a '/' before the project name
  local workspace_dir = home .. '/.cache/jdtls-workspace/' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

  -- =======================================================================
  -- 4. CAPABILITIES (Autocompletion)
  -- =======================================================================

  local capabilities = vim.lsp.protocol.make_client_capabilities()
  -- If using nvim-cmp, verify capabilities
  local cmp_status, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
  if cmp_status then
    capabilities = cmp_nvim_lsp.default_capabilities()
  end

  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  -- =======================================================================
  -- 5. CONFIGURATION
  -- =======================================================================

  local config = {
    cmd = {
      -- CRITICAL: Use Java 21 executable here
      java_21_home .. '/bin/java',

      '-Declipse.application=org.eclipse.jdt.ls.core.id1',
      '-Dosgi.bundles.defaultStartLevel=4',
      '-Declipse.product=org.eclipse.jdt.ls.core.product',
      '-Dlog.protocol=true',
      '-Dlog.level=ALL',
      '-Xmx1g',
      '--add-modules=ALL-SYSTEM',
      '--add-opens',
      'java.base/java.util=ALL-UNNAMED',
      '--add-opens',
      'java.base/java.lang=ALL-UNNAMED',

      '-jar',
      launcher_jar,
      '-configuration',
      config_path,
      '-data',
      workspace_dir,
    },

    root_dir = require('jdtls.setup').find_root { '.git', 'mvnw', 'gradlew' },

    -- Load bundles and extended caps
    init_options = {
      bundles = bundles,
      extendedClientCapabilities = extendedClientCapabilities,
    },

    capabilities = capabilities,

    settings = {
      java = {
        eclipse = {
          downloadSources = true,
        },
        configuration = {
          updateBuildConfiguration = 'interactive',
          runtimes = {
            {
              name = 'JavaSE-17',
              path = java_17_home,
              default = true,
            },
            {
              name = 'JavaSE-21',
              path = java_21_home,
            },
          },
        },
        maven = {
          downloadSources = true,
        },
        implementationsCodeLens = { enabled = true },
        referencesCodeLens = { enabled = true },
        references = { includeDecompiledSources = true },
        signatureHelp = { enabled = true },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
      },
    },

    on_attach = function(client, bufnr)
      -- Standard DAP setup
      if debug_path then
        require('jdtls').setup_dap { hotcodereplace = 'auto' }
        require('jdtls.dap').setup_dap_main_class_configs()
      end

      -- Add your keymaps here or let your default LSP config handle it
    end,
  }

  if not config.root_dir then
    -- Optional: Don't start JDTLS if no root found (avoids attaching to random single files properly)
    return
  end

  jdtls.start_or_attach(config)
end)

if not status then
  vim.notify('JDTLS configuration error: ' .. tostring(result), vim.log.levels.ERROR)
end
