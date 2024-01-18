"--- Functions

function! TestOllamaConnection()
  let l:ip_port = g:vim_llama_ip . ":" . g:vim_llama_port
  if !executable("curl")
    echoerr "ERROR: Curl not found!"
    return 1
  elseif !executable("ping")
    echoerr "ERROR: Ping not found!"
    return 1
  endif
  let l:output = system("curl --connect-timeout 2 -sL -w \"%{http_code}\" http://" . l:ip_port)
  if l:output !~# '200$'
    echomsg "Testing if ollama is reachable at " . l:ip_port
    echoerr "ERROR: IP/Port not reachable!"
    return 1
  endif
  return 0
endfunction

"--- CST handling

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

if ! exists("g:vim_llama_run_script")
  let g:vim_llama_run_script = expand("<sfile>:p:h:h") . "/scripts/run_ollama.py"
endif

if TestOllamaConnection()
  finish
endif

"--- Aliases

command! -nargs=* -range VLMAStart call vim_llama#StartWithCtx(<range>,<line1>, <line2>, <q-args>)
command! -nargs=0 VLMAStop call vim_llama#Stop()
command! -nargs=0 VLMALogs call vim_llama#DisplayLogs()
command! -nargs=1 VLMAPull call vim_llama#Pull(<f-args>)
command! -nargs=0 VLMAPrompt call vim_llama#Prompt()

