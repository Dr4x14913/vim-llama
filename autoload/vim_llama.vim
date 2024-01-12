function! vim_llama#Start(isrange, lstart, lend, ...)

  let s:additional_prompts = split(a:1, ",")
  if len(s:additional_prompts) >= 1
    let s:additional_prompt_0 = s:additional_prompts[0] . "\n```"
    if len(s:additional_prompts) >= 2
      let s:additional_prompt_1 = "\n```\n" . s:additional_prompts[1]
    else
      let s:additional_prompt_1 = "\n```\nOutput the code between ``` and ``` quotes."
    endif
  else
      let s:additional_prompt_1 = "\n```\nOutput the code between ``` and ``` quotes."
      let s:additional_prompt_0 = "Continue the following code:\n```"
  endif

  let s:cur_buf                 = bufnr("%")
  call bufload      (s:cur_buf)
  call appendbufline(s:cur_buf, a:lend, "")

  if a:isrange == 0
    let s:lstart = Max(1, a:lend - g:vim_llama_context_size)
  else
    let s:lstart = a:lstart
  endif

  let s:context                 = join(getbufline(s:cur_buf, s:lstart, a:lend), "\n")
  let s:last_ended              = a:lend + 1
  let s:last_timecode           = 0
  let s:stopped                 = 0
  let cmd                       = g:vim_llama_run_script . " --model " . g:vim_llama_model
  let cmd                       = cmd          . " --ip "    . g:vim_llama_ip
  let cmd                       = cmd          . " --port "  . g:vim_llama_port . " &"

  if filereadable(expand(g:vim_llama_run_script)) == 0
    echo "Cant find run script at " . s:run_script
    return
  endif

  call system("echo '" . s:additional_prompt_0 . "' > .vimllama.ctx")
  call system("echo '" . s:context . "' >> .vimllama.ctx")
  call system("echo '" . s:additional_prompt_1 . "' >> .vimllama.ctx")
  call system("echo '" . cmd . "' > .vimllama.cmd")
  call system(cmd)
  call timer_start(5000, 'vim_llama#Fetch')
endfunction

" Fetch function that gathers responses and render text
function! vim_llama#Fetch(timer)
  echo "fetching " . s:last_timecode
  " Only if normal mode
  if mode() != "n"
    if s:stopped == 0
      call timer_start(1000, 'vim_llama#Fetch')
    endif
    return
  endif

  " Gather each response from the out file
  let res           = readfile(".vimllama.resp")
  let string_to_add = ""
  let s:register    = 0
  for j in res
    " If json not complete, stop parsing, it mean that we've reached the end
    " of the file for now
    try
      let obj = json_decode(j)
    catch
      break
    endtry
    if len(get(obj, "error")) > 1
      echo "Error: " . get(obj, "error")
      let s:stopped = 1
      break
    endif
    let s:timecode = get(obj, "created_at")
    if get(obj, "done")
      let s:stopped = 1
    endif
    if s:last_timecode == 0
      let s:register = 1
    endif
    if s:register == 1
      let string_to_add = string_to_add . get(obj, "response")
      let s:last_timecode = s:timecode
    endif
    if s:timecode == s:last_timecode
      let s:register = 1
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

  if s:stopped == 0
    call timer_start(100, 'vim_llama#Fetch')
  endif
endfunction

function! vim_llama#Stop()
  "let s:pid = system("ps x | grep codellama | grep -v grep | awk -F' ' '{print $1}' | tail -1")
  "echo "killed \n"
  call system("touch .vimllama.stop")
  let s:stopped = 1
endfunction

function! vim_llama#Pull(model)
  let json = {"name": a:model}
  let cmd = "curl -X POST http://" . g:vim_llama_ip . ":" . g:vim_llama_port . "/api/pull -d '" . json_encode(json) . "' > .vimllama.pull &"
  echo cmd
  echo "It may took some time..."
  call system(cmd)
  call timer_start(2500, 'vim_llama#FetchPull')
endfunction

function! vim_llama#FetchPull(timer)
  " Gather each response from the out file
  let file = readfile(".vimllama.pull")
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

function! Max(a,b)
  return a:a > a:b ? a:a : a:b
endfunction

function! Min(a,b)
  return a:a < a:b ? a:a : a:b
endfunction
