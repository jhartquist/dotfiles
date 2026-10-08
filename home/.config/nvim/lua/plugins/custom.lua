return {

  -----------------------------------------------------------------------------
  -- COMPLETION: Use Tab to accept instead of Enter
  -----------------------------------------------------------------------------
  {
    "saghen/blink.cmp",
    opts = {
      enabled = function()
        return vim.bo.filetype ~= "markdown"
      end,
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_and_accept", "fallback" },
        ["<CR>"] = {}, -- disable Enter for completion
      },
    },
  },

  -----------------------------------------------------------------------------
  -- COPILOT: Toggle keymap
  -----------------------------------------------------------------------------
  {
    "zbirenbaum/copilot.lua",
    keys = {
      {
        "<leader>ai",
        function()
          local copilot = require("copilot")
          if not copilot.setup_done then
            copilot.setup(LazyVim.opts("copilot.lua"))
            vim.notify("Copilot enabled")
          elseif require("copilot.client").is_disabled() then
            vim.cmd("Copilot enable")
            vim.notify("Copilot enabled")
          else
            vim.cmd("Copilot disable")
            vim.notify("Copilot disabled")
          end
        end,
        desc = "Toggle Copilot",
      },
    },
    -- start disabled: setup() runs on the first <leader>ai. Calling setup()
    -- then disabling races its scheduled buffer attaches, which warn
    -- "copilot is disabled".
    config = function() end,
  },

  -----------------------------------------------------------------------------
  -- PANE NAVIGATION (tmux)
  -----------------------------------------------------------------------------
  -- Allows Ctrl+h/j/k/l to move between NeoVim and tmux panes seamlessly
  -- Requires: vim-tmux-navigator in your .tmux.conf; nvim maps in keymaps.lua
  { "christoomey/vim-tmux-navigator", cond = vim.env.TMUX ~= nil },

  -----------------------------------------------------------------------------
  -- PANE NAVIGATION (herdr)
  -----------------------------------------------------------------------------
  -- Same, for herdr: Ctrl+h/j/k/l nav, Alt+h/j/k/l resize, across herdr panes
  -- and nvim splits. Herdr half: `herdr plugin install lmilojevicc/herdr-splits.nvim`
  -- plus [[keys.command]] binds in herdr's config.toml.
  {
    "lmilojevicc/herdr-splits.nvim",
    cond = vim.env.HERDR_ENV == "1",
    event = "VeryLazy",
    config = function()
      require("herdr-splits").setup()
    end,
    keys = {
      { "<C-h>", function() require("herdr-splits").move_cursor_left() end, desc = "Navigate left" },
      { "<C-j>", function() require("herdr-splits").move_cursor_down() end, desc = "Navigate down" },
      { "<C-k>", function() require("herdr-splits").move_cursor_up() end, desc = "Navigate up" },
      { "<C-l>", function() require("herdr-splits").move_cursor_right() end, desc = "Navigate right" },
      { "<M-h>", function() require("herdr-splits").resize_left() end, desc = "Resize left" },
      { "<M-j>", function() require("herdr-splits").resize_down() end, desc = "Resize down" },
      { "<M-k>", function() require("herdr-splits").resize_up() end, desc = "Resize up" },
      { "<M-l>", function() require("herdr-splits").resize_right() end, desc = "Resize right" },
    },
  },

  -----------------------------------------------------------------------------
  -- COLORSCHEME
  -----------------------------------------------------------------------------
  {
    "luisiacc/gruvbox-baby",
    config = function()
      vim.g.gruvbox_baby_transparent_mode = true
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "gruvbox-baby" },
  },

  -----------------------------------------------------------------------------
  -- LSP: Disable inlay hints by default (toggle with <space>uh)
  --      + auto-detect Python venv (.venv/) upward from the open buffer
  -----------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.inlay_hints = { enabled = false }

      local function set_venv_python(_, config)
        local bufname = vim.api.nvim_buf_get_name(0)
        local dir = bufname ~= "" and vim.fn.fnamemodify(bufname, ":p:h") or vim.fn.getcwd()
        local venv = vim.fs.find(".venv", { upward = true, path = dir, type = "directory" })[1]
        if venv then
          local python = venv .. "/bin/python"
          if vim.fn.executable(python) == 1 then
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = python
          end
        end
      end

      opts.servers = opts.servers or {}
      for _, name in ipairs({ "pyright", "basedpyright" }) do
        opts.servers[name] = opts.servers[name] or {}
        opts.servers[name].before_init = set_venv_python
      end

      -- Ruby: the project's pinned standardrb, not Mason's rubocop
      opts.servers.rubocop = { enabled = false }
      opts.servers.standardrb = { cmd = { "bundle", "exec", "standardrb", "--lsp" } }
      opts.servers.ruby_lsp = { mason = false } -- the mise-installed gem, not Mason's 3.4 build
    end,
  },

  -----------------------------------------------------------------------------
  -- STATUSLINE: MINIMAL
  -----------------------------------------------------------------------------
  -- Hides the right side of the statusline (encoding, position, etc.)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      sections = {
        lualine_x = {},
        lualine_y = {},
        lualine_z = {},
      },
    },
  },

  -----------------------------------------------------------------------------
  -- NOICE: COMMAND LINE TWEAKS
  -----------------------------------------------------------------------------
  -- Native cmdline position, disable LSP progress, hide "written" messages
  {
    "folke/noice.nvim",
    opts = {
      cmdline = { view = "cmdline" },
      lsp = { progress = { enabled = false } },
      routes = {
        { filter = { event = "msg_show", kind = "", find = "written" }, opts = { skip = true } },
      },
    },
  },

  -----------------------------------------------------------------------------
  -- CONFORM: Use prettierd for JS/TS, fall back to prettier
  -----------------------------------------------------------------------------
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        typescript = { "prettierd", "prettier" },
        javascript = { "prettierd", "prettier" },
        typescriptreact = { "prettierd", "prettier" },
        javascriptreact = { "prettierd", "prettier" },
      },
    },
  },

  -----------------------------------------------------------------------------
  -- SNACKS.NVIM TWEAKS
  -----------------------------------------------------------------------------
  -- Disable indent guides, smooth scroll; configure zen mode
  {
    "snacks.nvim",
    opts = {
      indent = { enabled = false },
      -- lazygit `e` hides the float instead of quitting (the nvim-remote
      -- preset sends "q"), so <leader>gg returns to the same spot
      lazygit = {
        -- under herdr, Ctrl-hjkl in the float moves to the neighboring herdr
        -- pane (lazygit's own <c-j>/<c-k>/<c-l> are lost, same as in a plain
        -- herdr lazygit pane)
        win = vim.env.HERDR_ENV == "1" and {
          keys = {
            nav_h = { "<C-h>", function() require("herdr-splits").move_cursor_left() end, expr = false, mode = "t" },
            nav_j = { "<C-j>", function() require("herdr-splits").move_cursor_down() end, expr = false, mode = "t" },
            nav_k = { "<C-k>", function() require("herdr-splits").move_cursor_up() end, expr = false, mode = "t" },
            nav_l = { "<C-l>", function() require("herdr-splits").move_cursor_right() end, expr = false, mode = "t" },
          },
        } or nil,
        config = {
          os = {
            edit = [[nvim --server "$NVIM" --remote-send '<C-\><C-n>:close<CR>' && nvim --server "$NVIM" --remote {{filename}}]],
            editAtLine = [[nvim --server "$NVIM" --remote-send '<C-\><C-n>:close<CR>' && nvim --server "$NVIM" --remote {{filename}} && nvim --server "$NVIM" --remote-send ':{{line}}<CR>']],
          },
        },
      },
      scroll = { enabled = false },
      -- hidden = dotfiles like .env.example; explorer also shows gitignored paths
      picker = {
        sources = {
          explorer = { hidden = true, ignored = true },
          files = { hidden = true },
          grep = { hidden = true },
        },
      },
      zen = {
        toggles = { dim = false, diagnostics = false },
        show = { statusline = false, tabline = false },
      },
      styles = {
        zen = { width = 80, wo = { wrap = true } },
      },
    },
  },
}
