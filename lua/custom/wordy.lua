vim.schedule(function()
  vim.notify 'wordy init loaded'
end)

local M = {}

local ns = vim.api.nvim_create_namespace 'word_jump_ns'

local LABEL_CHARS = {}
do
  for c = string.byte 'a', string.byte 'z' do
    table.insert(LABEL_CHARS, string.char(c))
  end
end

local rx = vim.regex [[\k\+]]

local function find_visible_words(win)
  win = win or 0
  local buf = vim.api.nvim_win_get_buf(win)

  local topline = vim.fn.line 'w0' - 1
  local botline = vim.fn.line 'w$' - 1

  local results = {}
  -- local word_pattern = [[\k\+]]

  for lnum = topline, botline do
    local line = vim.api.nvim_buf_get_lines(buf, lnum, lnum + 1, false)[1]
    if line and line ~= '' then
      local start_col = 0
      while start_col <= #line do
        local s, e = rx:match_str(line:sub(start_col + 1))
        if not s then
          break
        end
        local col0 = start_col + s
        local end0 = start_col + e
        local word = line:sub(col0 + 1, end0)
        table.insert(results, { lnum = lnum, col = col0, word = word })
        start_col = end0
        -- start = (start - 1) + e + 1
        if start_col >= #line then
          break
        end
      end
    end
  end

  return results
end

local function read_two_chars_onkey(cb)
  local keys = {}
  local token = vim.api.nvim_create_namespace 'wordy_on_key'

  local function finish(result)
    vim.on_key(nil, token)
    cb(result)
  end

  local function handler(ch)
    if ch == '\027' then -- for Esc, I guess
      return finish(nil)
    end

    if #ch == 0 then
      return
    end

    table.insert(keys, ch)
    if #keys >= 2 then
      return finish(table.concat(keys))
    end
  end

  vim.on_key(handler, token)
end

local function render_labels(win, entries, labels, opts)
  opts = opts or {}
  -- local virt_hl = opts.highlight or 'IncSearch'
  local buf = vim.api.nvim_win_get_buf(win)
  local marks = {}

  for i, entry in ipairs(entries) do
    local label = labels[i]
    if not label then
      break
    end

    -- Better colors, you know
    vim.api.nvim_set_hl(0, 'SoftVirt', { fg = '#fbff00', bg = 'NONE', italic = true })

    local virt_hl = 'SoftVirt'
    local mark_id = vim.api.nvim_buf_set_extmark(buf, ns, entry.lnum, entry.col, {
      virt_text = { { label, virt_hl } },
      virt_text_pos = 'overlay',
      hl_mode = 'combine',
    })
    marks[label] = {
      id = mark_id,
      lnum = entry.lnum,
      col = entry.col,
      word = entry.word,
    }
    -- if i <= 5 then
    --   vim.print { placed = true, lnum = entry.lnum, col = entry.col, id = mark_id, label = label }
    -- end
  end
  return marks
end

local function generate_labels(n)
  local labels = {}
  local total = #LABEL_CHARS * #LABEL_CHARS

  if n > total then
    local msg = ('wordy: need %d labels but only %d available'):format(n, total)
    vim.notify(msg, vim.log.levels.WARN)
    n = math.min(n, total)
  end

  local count = 0
  for i = 1, #LABEL_CHARS do
    for j = 1, #LABEL_CHARS do
      count = count + 1
      labels[count] = LABEL_CHARS[i] .. LABEL_CHARS[j]
      if count == n then
        return labels
      end
    end
  end
  return labels
end

local function read_two_chars(prompt)
  local ok, res = pcall(vim.fn.input, prompt or 'label: ')
  if not ok then
    return nil
  end

  res = tostring(res or '')
  if #res ~= 2 then
    return nil
  end
  return res
end

local function clear_labels(win)
  local buf = vim.api.nvim_win_get_buf(win)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

function M.activate(opts)
  opts = opts or {}
  local win = 0
  local buf = vim.api.nvim_win_get_buf(win)

  local words = find_visible_words(win)

  if #words == 0 then
    vim.notify('wordy: no words in view', vim.log.levels.INFO)
    return
  end

  local labels = generate_labels(#words)

  local marks = render_labels(win, words, labels, opts)
  -- FUGLY. Schedule with a callback
  vim.schedule(function()
    vim.cmd 'redraw'
  end)

  -- read_two_chars_onkey(function(label)
  --   clear_labels(win)
  --
  --   if not label then
  --     return
  --   end
  --
  --   label = string.lower(label)
  --   local target = marks[label]
  --   if not target then
  --     vim.notify("Wordy: no match for '" .. label .. "'", vim.log.levels.INFO)
  --   end
  -- end)

  local label = read_two_chars(opts.prompt or 'Jump: ')
  clear_labels(win)

  if not label then
    return
  end
  -- local label = read_two_chars(opts.prompt or 'Jump: ')
  label = string.lower(label)

  local target = marks[label]
  if not target then
    vim.notify("wordy: no match for '" .. label .. "'", vim.log.levels.INFO)
  end

  vim.api.nvim_win_set_cursor(win, { target.lnum + 1, target.col })

  if opts.center then
    vim.cmd 'normal! zz'
  end
end

function M.setup(config)
  config = config or {}
  M.config = config
  if config.map ~= false then
    vim.keymap.set('n', config.map or 'gw', function()
      M.activate(config)
    end, { desc = 'Wordy: label and jump to visible words' })
  end
end

-- vim.print { M = M }

return M
