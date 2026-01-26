local status, result = pcall(function()
  local jdtls = require 'jdtls'
  local home = os.getenv 'HOME'

  -- Bypass Mason Registry and look directly in the data directory
  -- Standard location: ~/.local/share/nvim/mason/packages/
  local mason_packages = vim.fn.stdpath 'data' .. '/mason/packages'

  local function get_package_path(package)
    local path = mason_packages .. '/' .. package
    if vim.fn.isdirectory(path) ~= 1 then
      error('Folder not found: ' .. path .. '\nDid you run :MasonInstall ' .. package .. '?')
    end
    return path
  end

  local jdtls_path = get_package_path 'jdtls'
  local debug_path = get_package_path 'java-debug-adapter'
  local test_path = get_package_path 'java-test'

  -- The Linux specific config path
  local config_path = jdtls_path .. '/config_linux'
  local launcher_jar = vim.fn.glob(jdtls_path .. '/plugins/org.eclipse.equinox.launcher_*.jar')

  if launcher_jar == '' then
    error('Could not find launcher jar in: ' .. jdtls_path .. '/plugins/')
  end

  local bundles = {
    vim.fn.glob(debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar', 1),
  }
  vim.list_extend(bundles, vim.split(vim.fn.glob(test_path .. '/extension/server/*.jar', 1), '\n'))

  local workspace_dir = home .. '/.cache/jdtls-workspace' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')

  local config = {
    cmd = {
      '/usr/lib/jvm/java-21-openjdk-amd64/bin/java',
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
    root_dir = require('jdtls.setup').find_root { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' },
    init_options = { bundles = bundles },
    on_attach = function(client, bufnr)
      require('jdtls').setup_dap { hotcodereplace = 'auto' }
      require('jdtls.dap').setup_dap_main_class_configs()
    end,
  }

  if not config.root_dir then
    print '!!! WARNING: No root dir found. Please git init !!!'
    return
  end

  jdtls.start_or_attach(config)
end)

if not status then
  print('!!! JAVA ERROR !!!: ' .. tostring(result))
end
