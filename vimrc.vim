:set viminfo='100,<50,s10,h,%
let g:surround_99 = "{/* \r */}" " Sc

colorscheme tokyonight-night

" Dont know why this is needed but it fixes quickfix list window
autocmd BufReadPost quickfix nnoremap <buffer> <CR> <CR>
