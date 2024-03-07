"-----------------------------------------------------------------------------------------
"-- Start functions
"-----------------------------------------------------------------------------------------
function! vim_llama#StartWithCtx(isrange, lstart, lend, ...)
  " Loading current buffer
  let s:cur_buf = bufnr("%")
  call bufload      (s:cur_buf)
  call appendbufline(s:cur_buf, a:lend, "")

  " Init variable before run
  let s:lstart        = (a:isrange == 0 ? Max(1, a:lend - g:vim_llama_context_size) : a:lstart)
  let s:context       = join(getbufline(s:cur_buf, s:lstart, a:lend), "\n")
  let s:only_code     = 1
  let s:last_timecode = 0
  let s:last_ended    = a:lend + 1
  let s:stopped       = 0
  let s:log = get(s:, 'log', [])

  " Last argument handing
  let s:additional_prompts = split(a:1, ",")
  if len(s:additional_prompts) >= 1
    let s:only_code           = 0 " Base prompt is changed, output everything
    let s:additional_prompt_0 = s:additional_prompts[0] . "\n```" . vim_llama#GetLanguage()
    if len(s:additional_prompts) >= 2
      let s:additional_prompt_1 = "\n```\n" . s:additional_prompts[1]
    else
      let s:additional_prompt_1 = "\n```\nOutput the code between ``` and ``` quotes."
    endif
  else
      let s:additional_prompt_0 = "Continue this code from where it stopped:\n```" . vim_llama#GetLanguage()
      let s:additional_prompt_1 = "\n```\nOutput the code between ``` and ``` quotes."
  endif
  call vim_llama#Log("Only output what's inside ``` quotes: " . s:only_code)

  let l:prompt = s:additional_prompt_0 . "\n" . s:context . "\n" . s:additional_prompt_1
  call vim_llama#Start(l:prompt)
endfunction

function! vim_llama#Start(prompt)
  " Check if model is pulled on the server
  if vim_llama#Check_model()
    echo "vim-llama didnt start due to previous errors"
    return
  endif

  " Create env for this run
  call vim_llama#CreateTmpEnv()

  " Building system command
  let cmd                       = g:vim_llama_run_script . " --model " . g:vim_llama_model
  let cmd                       = cmd          . " --path "  . s:tmp_path
  let cmd                       = cmd          . " --ip "    . g:vim_llama_ip
  let cmd                       = cmd          . " --port "  . g:vim_llama_port . " "
  call vim_llama#Log("Command to be run: " . cmd)
  call vim_llama#Log("Prompt is:\n". a:prompt)


  if filereadable(expand(g:vim_llama_run_script)) == 0
    echo "Cant find run script at " . s:run_script
    return
  endif

  call system("echo -e '" . a:prompt . "' > " . s:tmp_path . "/.vimllama.ctx")
  call system("echo '" . cmd . "' > " . s:tmp_path . "/.vimllama.cmd")
  " call system(cmd)
  exec "AsyncRun " . cmd
  call timer_start(2000, 'vim_llama#Fetch')
endfunction

function! vim_llama#CreateTmpEnv()
  " Generate a random id
  let s:id = "vimllama" . matchstr(getcwd(), '\d\+$') . "-" . strftime("%Y%m%d-%H%M%S")
  call vim_llama#Log("Run id is: " . s:id)

  " Create a tmp folder in /tmp named as s:id
  let s:tmp_path = "/tmp/" . s:id
  call system("mkdir -p " . s:tmp_path)
  call vim_llama#Log("Work dir is: " . s:tmp_path)
endfunction

function! vim_llama#DefaultInit()
  let s:last_timecode = 0
  let s:last_ended    = 1
  let s:stopped       = 0
  let s:only_code     = 0
  let s:log           = get(s:,"log", [])
endfunction

" function that test if the ollama model is already pulled using curl
function! vim_llama#Check_model()
    let l:json_string = system("curl -X GET --silent http://". g:vim_llama_ip . ":" . g:vim_llama_port ."/api/tags")
    let l:json_object = json_decode(l:json_string)
    let l:models = get(l:json_object, "models")
    let l:models_name = []

    for model in l:models
      let name = get(model, "name")
      call add(l:models_name, name)
    endfor

    if index(l:models_name, g:vim_llama_model) >= 0
      return 0
    else
      echo g:vim_llama_model . " does not exist in the models list."
      echo "Model list: " . string(l:models_name)
      echo "Consider using one in the list or pulling it using `VLMAPull ".g:vim_llama_model."`"
      return 1
    endif
endfunction

"-----------------------------------------------------------------------------------------
"-- Fetch function
"-----------------------------------------------------------------------------------------
function! vim_llama#Fetch(timer)
  " Fetch function that gathers responses and render text
  let s:refresh_time = 200

  " Only if normal mode
  if mode() != "n"
    if s:stopped == 0
      call timer_start(s:refresh_time, 'vim_llama#Fetch')
    endif
    return
  endif

  if s:stopped
    echo "vim-llama run ended"
    call vim_llama#Log("Run " . s:id . " has finished")
    call vim_llama#Log("--------------------------------")
    return
  else
    echo "fetched " . s:last_timecode
  endif

  " Gather each response from the out file
  let res           = readfile("" . s:tmp_path . "/.vimllama.resp")
  let string_to_add = ""
  let s:register    = 0
  let s:is_between_quotes = 0 " Only used when s:only_code
  for j in res
    " If json not complete, stop parsing, it mean that we've reached the end
    " of the file for now
    try
      let obj = json_decode(j)
    catch
      break
    endtry

    " If errored
    if len(get(obj, "error")) > 1
      echo "Error: " . get(obj, "error")
      let s:stopped = 1
      break
    endif

    " If ollama is done
    let s:timecode = get(obj, "created_at")
    if get(obj, "done")
      let s:stopped = 1
    endif

    " If its the begining
    if s:last_timecode == 0
      let s:register = 1
    endif

    " If only_code then only dislay what's inside ``` quotes
    if s:only_code == 1 && get(obj, "response") == "```" && s:is_between_quotes == 1
      call vim_llama#Stop()
      break
    end
    if s:only_code == 1 && s:is_between_quotes != 1
      let s:register = 0
    endif

    " Gather all the new responses
    if s:register == 1
      let string_to_add = string_to_add . get(obj, "response")
      let s:last_timecode = s:timecode
    endif

    if s:timecode == s:last_timecode
      let s:register = 1
    endif

    if s:only_code == 1 && get(obj, "response") == "```" && s:is_between_quotes == 0
      let s:is_between_quotes = 0.5
    endif
    if s:is_between_quotes == 0.5 && get(obj, "response") == "\n"
      let s:is_between_quotes = 1
    endif
  endfor

  " If enougth data has been collected then diplay what was gathered
  if len(string_to_add) > 0
    " Load current buffer
    call bufload(s:cur_buf)
    let s:first = 1
    " Loop through each line
    for line in split(string_to_add, "\n", 1)
      " If first is 1 then we are on the same line that previous call so dont
      " append a new line but complete the previous one
      if s:first == 1
        let s:first = 0
        call setbufline(s:cur_buf, s:last_ended, getbufline(s:cur_buf, s:last_ended)[0] . line)
      else
        call appendbufline(s:cur_buf, s:last_ended, line)
        let s:last_ended = s:last_ended + 1
    endif
    endfor
  endif

  call timer_start(s:refresh_time, 'vim_llama#Fetch')
endfunction

function! vim_llama#Stop()
  "let s:pid = system("ps x | grep codellama | grep -v grep | awk -F' ' '{print $1}' | tail -1")
  "echo "killed \n"
  call system("touch " . s:tmp_path . "/.vimllama.stop")
  let s:stopped = 1
endfunction

"-----------------------------------------------------------------------------------------
"-- Pulling model functions
"-----------------------------------------------------------------------------------------
function! vim_llama#Pull(model)
  call vim_llama#CreateTmpEnv()
  let json = {"name": a:model}
  let cmd = "curl -X POST http://" . g:vim_llama_ip . ":" . g:vim_llama_port . "/api/pull -d '" . json_encode(json) . "' > " . s:tmp_path . "/.vimllama.pull &"
  echo cmd
  echo "It may took some time..."
  call system(cmd)
  call timer_start(2500, 'vim_llama#FetchPull')
endfunction

function! vim_llama#FetchPull(timer)
  " Gather each response from the out file
  let file = readfile(s:tmp_path . "/.vimllama.pull")
  try
    let res = file[-1]
    let obj = json_decode(res)
  catch
    try
      let res = file[-2]
      let obj = json_decode(res)
    catch
      call timer_start(1000, 'vim_llama#FetchPull')
      return
    endtry
  endtry

  if get(obj, "status") == "success"
    echo "Done"
    return
  endif

  if len(get(obj, "error")) > 1
    echo "Error: " . get(obj, "error")
    return
  endif

  echo get(obj, "status") . " (" . get(obj, "completed"). ")"

  call timer_start(200, 'vim_llama#FetchPull')
endfunction

function! vim_llama#Prompt()
  call vim_llama#DefaultInit()

  " Prompt user
  let l:user_input = input(g:vim_llama_model . '> ')

  " Setup buffer
  let l:bufname = "vimllama_prompt"
  if bufexists(l:bufname)
    execute 'bw ' . l:bufname
  endif
  execute 'botright vsplit ' . l:bufname
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal noswapfile

  " Loading current buffer
  let s:cur_buf = bufnr("%")
  call bufload(s:cur_buf)

  " Run model
  call vim_llama#Start(l:user_input)
endfunction

"-----------------------------------------------------------------------------------------
"-- Log handling
"-----------------------------------------------------------------------------------------
" Log function with time stamp that add a line to the s:log variable
function! vim_llama#Log(log_msg)
  let current_time = strftime("%H:%M:%S")
  let s:log        = get(s:, 'log', [])
  call add(s:log, '[' . current_time . '] ' . split(a:log_msg, "\n")[0])
  for i in split(a:log_msg, "\n")[1:-1]
    call add(s:log, "           " . i)
  endfor
endfunction

" function that open a new splited readonly vim buffer and display the s:log list
function! vim_llama#DisplayLogs()
  let l:bufname = "vimllama_logs"
  if bufexists(l:bufname)
    execute 'bw ' . l:bufname
  endif
  execute 'silent split ' . l:bufname
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal noswapfile

  let s:log = get(s:, 'log', [])
  call append(0, s:log)
  setlocal nomodifiable
endfunction

"-----------------------------------------------------------------------------------------
"-- MISC
"-----------------------------------------------------------------------------------------
function! Max(a,b)
  return a:a > a:b ? a:a : a:b
endfunction

function! Min(a,b)
  return a:a < a:b ? a:a : a:b
endfunction

function! vim_llama#GetLanguage()
  let s:cur_buf = bufnr("%")
  call bufload(s:cur_buf)
  " If vimbuffer 1st line is a shabang
  let l:firstline = getbufline(s:cur_buf, 1, 1)[0]
  if l:firstline =~ '^#!'
    return matchstr(l:firstline, '[^/]\+$')
  else
    return ""
  endif
endfunction
