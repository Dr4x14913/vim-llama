if exists("g:loaded_vim_llama")
    finish
endif
let g:loaded_vim_llama = 1

if ! exists("g:vim_llama_context_size")
  let g:vim_llama_context_size = 10
endif

if ! exists("g:vim_llama_model")
  let g:vim_llama_model = "codellama"
endif

command! -nargs=0 VLMAStart call vim_llama#Start()
command! -nargs=0 VLMAFetch call vim_llama#Fetch()
command! -nargs=0 VLMAStop call vim_llama#Stop()
