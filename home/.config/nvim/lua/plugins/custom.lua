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
          -- deferred so it reads the settled state even when this keypress
          -- is what lazy-loads the plugin
          vim.schedule(function()
            if require("copilot.client").is_disabled() then
              vim.cmd("Copilot enable")
              vim.notify("Copilot enabled")
            else
              vim.cmd("Copilot disable")
              vim.notify("Copilot disabled")
            end
          end)
        end,
        desc = "Toggle Copilot",
      },
    },
    config = function(_, opts)
      require("copilot").setup(opts)
      -- start disabled; <leader>ai enables it on demand. Deferred a tick so
      -- it runs after copilot's own scheduled buffer-attach (avoids a
      -- "copilot is disabled" warning on startup).
      vim.schedule(function()
        vim.cmd("Copilot disable")
      end)
    end,
  },

  -----------------------------------------------------------------------------
  -- TMUX NAVIGATION (uncomment if you use tmux)
  -----------------------------------------------------------------------------
  -- Allows Ctrl+h/j/k/l to move between NeoVim and tmux panes seamlessly
  -- Requires: vim-tmux-navigator in your .tmux.conf
  { "christoomey/vim-tmux-navigator" },

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
  -- SNACKS.NVIM TWEAKS
  -----------------------------------------------------------------------------
  -- Disable indent guides, smooth scroll; configure zen mode
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

  {
    "snacks.nvim",
    opts = {
      indent = { enabled = false },
      scroll = { enabled = false },
      picker = { sources = { explorer = { hidden = true } } },
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
