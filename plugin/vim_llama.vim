if exists("g:loaded_vim_llama")
    finish
endif
let g:loaded_vim_llama = 1

if ! exists("g:vim_llama_context_size")
  let g:vim_llama_context_size = 20
endif

if ! exists("g:vim_llama_model")
  let g:vim_llama_model = "codellama"
endif

if ! exists("g:vim_llama_ip")
  let g:vim_llama_ip = "localhost"
endif

if ! exists("g:vim_llama_port")
  let g:vim_llama_port = "11434"
endif


command! -nargs=* -range VLMAStart call vim_llama#Start(<range>,<line1>, <line2>, <q-args>)
command! -nargs=0 VLMAFetch call vim_llama#Fetch()
command! -nargs=0 VLMAStop call vim_llama#Stop()
command! -nargs=1 VLMAPull call vim_llama#Pull(<f-args>)
