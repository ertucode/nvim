
local lsp = require('lsp-zero')

local cmp = require('cmp')

local cmp_mappings = lsp.defaults.cmp_mappings({

    ['<C-d'] = cmp.mapping.scroll_docs(-4),
    ['<C-f'] = cmp.mapping.scroll_docs(4),
    ['<C-e'] = cmp.mapping.close(),
    ['<C-y>'] = cmp.mapping.confirm({ select = true, behavior = cmp.ConfirmBehavior.Insert }),
    ["<C-Space>"] = cmp.mapping.complete(),
})

cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil

cmp.setup {
    mapping = cmp_mappings,
    sources = {
        {name = 'nvim_lua'},
        {name = 'nvim_lsp'},
        {name = 'path'},
        {name = 'luasnip'},
        {name = 'buffer', keyword_length = 1},
    },
    snippet = {
        expand = function (args)
           require('luasnip').lsp_expand(args.body)
        end
    },

    experimental = {
        ghost_text = true
    }
}

lsp.setup_nvim_cmp({
    mapping = cmp_mappings
})
