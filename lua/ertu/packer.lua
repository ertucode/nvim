vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use 'wbthomason/packer.nvim'

	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.1',
		-- or                            , branch = '0.1.x',
		requires = { {'nvim-lua/plenary.nvim'} }
	}

	use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
	use('theprimeagen/harpoon')
	use('mbbill/undotree')
	use('tpope/vim-fugitive')

	use {
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v2.x',
		requires = {
			-- LSP Support
			{'neovim/nvim-lspconfig'},             -- Required
			{                                      -- Optional
			'williamboman/mason.nvim',
			run = function()
				pcall(vim.cmd, 'MasonUpdate')
			end,
		},
		{'williamboman/mason-lspconfig.nvim'}, -- Optional

		-- Autocompletion
		{'hrsh7th/nvim-cmp'},     -- Required
		{'hrsh7th/cmp-nvim-lsp'}, -- Required -- Auto import
		{'L3MON4D3/LuaSnip'},     -- Required
	    }
    }

    -- completion
    use('hrsh7th/cmp-buffer') -- Get completion from current file even if its not a symbol
    use('hrsh7th/cmp-path')
    use('hrsh7th/cmp-nvim-lua') -- Knows nvim api
    use('saadparwaiz1/cmp_luasnip') -- Snip and comp adapter ?

    -- autopair
    use('windwp/nvim-autopairs')

    use('tpope/vim-surround')

    -- buffer file explorer
    use {
      'stevearc/oil.nvim',
      config = function() require('oil').setup() end
    }

    -- prettier
    use('jose-elias-alvarez/null-ls.nvim')
    use('MunifTanjim/prettier.nvim')

    -- nextjs snips
    use "avneesh0612/react-nextjs-snippets"

    -- comment
    use {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end
    }

    -- vscode theme
    use 'Mofiqul/vscode.nvim'
end)
