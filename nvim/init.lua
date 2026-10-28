-- 1. SETTINGS (Your init.vim converted to Lua)
vim.g.mapleader = ' ' -- Set space as leader
vim.g.mallocalleader= ' '
vim.opt.number = true
vim.opt.history = 500
vim.opt.showcmd = true
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.backspace = 'indent,eol,start'
vim.opt.tabstop = 4
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.termguicolors = true

-- Your 15-line jump habit (disabled in diff/fugitive buffers)
local function setup_jumps()
  vim.keymap.set('', '<Down>', '15j', { noremap = true })
  vim.keymap.set('', '<Up>', '15k', { noremap = true })
  vim.keymap.set('', '<Left>', '15h', { noremap = true })
  vim.keymap.set('', '<Right>', '15l', { noremap = true })
end

local function clear_jumps()
  vim.keymap.del('', '<Down>')
  vim.keymap.del('', '<Up>')
  vim.keymap.del('', '<Left>')
  vim.keymap.del('', '<Right>')
end

setup_jumps()

-- Disable aggressive jumps in diff/git buffers
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'diff', 'fugitive', 'fugitiveblame', 'DiffviewFiles', 'DiffviewFileHistory' },
  callback = function()
    clear_jumps()
  end,
})

-- CRUCIAL FOR CLAUDE: Auto-reload files when Claude modifies them
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  callback = function()
    if vim.fn.mode() ~= 'c' then vim.cmd('checktime') end
  end,
})

-- 2. PLUGIN MANAGER (Lazy.nvim)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- 3. PLUGINS
require("lazy").setup({
  -- Your Aesthetic
  { "morhetz/gruvbox", priority = 1000, config = function()
      vim.cmd("colorscheme gruvbox")
      vim.o.background = "dark"
      -- Softer diff colors with syntax highlighting preserved
      vim.api.nvim_create_autocmd('ColorScheme', {
        pattern = '*',
        callback = function()
          -- Blend=70 lets syntax highlighting show through the diff background
          vim.cmd("highlight DiffAdd ctermbg=22 guibg=#27403B blend=70")
          vim.cmd("highlight DiffDelete ctermbg=52 guibg=#3d2626 blend=70")
          vim.cmd("highlight DiffChange ctermbg=17 guibg=#273546 blend=70")
          vim.cmd("highlight DiffText ctermbg=24 guibg=#46556f blend=70")
        end,
      })
    end
  },
  { "vim-airline/vim-airline" },
  
  -- Your Workflow
  { "tpope/vim-surround" },
  { "vimwiki/vimwiki", init = function()
      vim.g.vimwiki_list = {{ path = '~/vimwiki/', syntax = 'markdown', ext = '.md' }}
    end 
  },

  -- FUZZY FINDING (replaces GoLand's Cmd+Shift+O and Cmd+Shift+F)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git/", "vendor/", "%.pb%.go" },
        },
      })
      telescope.load_extension("fzf")
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep across files" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
      { "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume last search" },
      { "<leader>fs", "<cmd>Telescope grep_string<cr>", desc = "Search word under cursor" },
    },
  },

  -- File tree (like GoLand's Project panel)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = { { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" } },
    config = function()
      require("nvim-tree").setup({
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
      })
    end,
  },

  -- Better quickfix for search results
  { "kevinhwang91/nvim-bqf", ft = "qf" },

  -- THE 2026 AI UPGRADE
  {
    "nandoolle/claude-code.nvim",
    cmd = "ClaudeCode",
    config = function()
      require("claude-code").setup({
        -- plugin specific settings
      })
    end,
  },

  {
    "sindrets/diffview.nvim",
    cmd = "DiffviewOpen",
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,
        view = {
          default = { layout = "diff2_horizontal" },
          merge_tool = { layout = "diff3_horizontal" },
        },
        hooks = {
          diag_before_open = function()
            -- Softer backgrounds that blend with syntax highlighting
            vim.cmd("highlight DiffAdd ctermbg=22 guibg=#27403B blend=70")
            vim.cmd("highlight DiffDelete ctermbg=52 guibg=#3d2626 blend=70")
            vim.cmd("highlight DiffChange ctermbg=17 guibg=#273546 blend=70")
            vim.cmd("highlight DiffText ctermbg=24 guibg=#46556f blend=70")
          end,
        },
      })
    end,
  }, -- Git history viewer with syntax highlighting + softer colors
  
  -- LSP (Go & Python) using the new native 0.11+ API
  { 
   "neovim/nvim-lspconfig",
    config = function()
      -- 1. Configure Go (gopls)
      vim.lsp.config('gopls', {
        settings = {
          gopls = {
            analyses = { unusedparams = true },
            staticcheck = true,
          },
        },
      })

      -- 2. Configure Python (pyright)
      vim.lsp.config('pyright', {})

      -- 3. Enable them (This replaces the old .setup() calls)
      vim.lsp.enable({ 'gopls', 'pyright' })
      
      -- 4. Keymaps (Standard LSP actions)
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local opts = { buffer = args.buf }
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        end,
      })

      -- Automatically fix imports/formatting after Claude writes a file
      vim.api.nvim_create_autocmd("BufWritePost", {
        pattern = { "*.go", "*.py" },
        callback = function()
          vim.lsp.buf.format({ async = true })
        end,
      })
    end
  }
})

-- 3. GLOBAL KEYMAPS (Put these at the bottom of the file)
-- This ensures they exist regardless of the plugin's internal state
vim.keymap.set('n', '<leader>ac', ':ClaudeCode<CR>', { desc = 'Toggle Claude Code', silent = true })

-- Open GoLand's visual diff for the current git project vs the latest commit
vim.keymap.set('n', '<leader>gd', function()
    local project_root = vim.fn.getcwd()
    -- This assumes you want to compare the current state with the git index
    -- but you can also pass two specific paths
    os.execute("goland diff " .. project_root .. " . &")
end, { desc = "Open GoLand Diff Tool" })

-- Define a highlight group for bad characters (Red background)
vim.api.nvim_set_hl(0, "NonBreakSpace", { bg = "#FF0000", fg = "#FFFFFF" })
-- Apply the highlight to the Unicode non-breaking space
vim.fn.matchadd("NonBreakSpace", [[\%u00a0]])
