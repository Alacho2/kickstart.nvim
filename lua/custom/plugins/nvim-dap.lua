return {
  'mfussenegger/nvim-dap',
  event = 'VeryLazy',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'jay-babu/mason-nvim-dap.nvim',
    'theHamsta/nvim-dap-virtual-text',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {

      automatic_installation = true,

      ensure_installed = {
        'javadbg',
        'javatest',
        'coreclr',
      },
      handlers = {
        function(config)
          require('mason-nvim-dap').default_setup(config)
        end,
      },
    }

    dap.configurations.cs = {
      {
        type = 'coreclr',
        name = 'launch - netcoredbg',
        request = 'launch',
        console = 'integratedTerminal',
        cwd = function()
          if vim.g.dap_cs_dll_path then
            return vim.fn.fnamemodify(vim.g.dap_cs_dll_path, ':h:h:h')
          end
          return vim.fn.getcwd()
        end,
        program = function()
          -- 1. Check cache (so you don't have to pick every time)
          if vim.g.dap_cs_dll_path and vim.fn.filereadable(vim.g.dap_cs_dll_path) == 1 then
            return vim.g.dap_cs_dll_path
          end

          -- 2. "Deep Search" for DLLs
          -- We look in the current folder AND all subfolders for any bin/Debug structure
          local cwd = vim.fn.getcwd()
          -- The '**' is the magic part that looks in all subdirectories
          local raw_output = vim.fn.glob(cwd .. '/**/bin/Debug/**/*.dll', false, true)

          local dlls = {}
          for _, path in ipairs(raw_output) do
            -- Filter out garbage
            local is_ref = path:find '/ref/'
            local is_dependency = path:find 'System.' or path:find 'Microsoft.'

            if not is_ref and not is_dependency then
              local relative_path = path:gsub(cwd .. '/', '')

              local short_path = relative_path
              short_path = short_path:gsub('/bin/Debug/net[%w%.]+/', '/')
              short_path = short_path:gsub('/bin/Debug/', '/')

              -- Make the path look nicer in the UI (relative to cwd)
              -- local display_path = path:gsub(cwd .. '/', '')
              table.insert(dlls, { path = path, display = short_path })
            end
          end

          -- 3. Handle results
          if #dlls == 0 then
            -- Fallback if nothing found (maybe you haven't built yet?)
            return vim.fn.input('Path to dll: ', vim.fn.getcwd() .. '/', 'file')
          elseif #dlls == 1 then
            -- Only one found? Just use it.
            vim.g.dap_cs_dll_path = dlls[1].path
            return dlls[1].path
          else
            -- Multiple found (e.g. MainProject + Tests) -> Ask User
            return coroutine.create(function(dap_run_co)
              local items = {}
              for _, item in ipairs(dlls) do
                table.insert(items, item.display)
              end

              vim.ui.select(items, { prompt = 'Select DLL to debug:' }, function(choice)
                if choice then
                  -- Find the full path based on the display choice
                  for _, item in ipairs(dlls) do
                    if item.display == choice then
                      vim.g.dap_cs_dll_path = item.path
                      coroutine.resume(dap_run_co, item.path)
                      return
                    end
                  end
                else
                  coroutine.resume(dap_run_co, nil)
                end
              end)
            end)
          end
        end,
      },
    }

    dapui.setup()
    require('nvim-dap-virtual-text').setup {}

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    -- dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    -- dap.listeners.before.event_exited['dapui_config'] = dapui.close

    vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', '<F2>', dap.continue, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', '<F3>', dap.continue, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', '<leader>B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Toggle Breakpoint' })
  end,
}
