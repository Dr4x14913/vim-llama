if exists("g:loaded_codellama")
    finish
endif
let g:loaded_codellama = 1

if ! exists("g:codellama_context_size")
  let g:codellama_context_size = 10
endif

command! -nargs=0 Start call codellama#Start()
command! -nargs=0 Fetch call codellama#Fetch()
command! -nargs=0 Stop call codellama#Stop()
