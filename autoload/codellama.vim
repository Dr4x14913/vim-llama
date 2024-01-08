
function! codellama#Start()

  let s:cur_buf                 = bufnr("%")
  call bufload      (s:cur_buf)
  call appendbufline(s:cur_buf, line("."), "")

  let s:last_ended              = line(".")
  let s:last_timecode           = 0
  let s:stopped                 = 0
  let s:context                 = join(getline(Max(line(".") - g:codellama_context_size, 1), line(".")), "\n")
  let s:run_script              = "~/projects/vim-llama/scripts/run_codellama.py"
  let cmd                       = s:run_script . " &"

  if filereadable(expand(s:run_script)) == 0
    echo "Cant find run_codellama.py script in " . s:run_script
    return
  endif

  call system("echo '" . s:context . "' > .codellama.ctx")
  call system("echo '" . cmd . "' > .codellama.cmd")
  call system(cmd)
  call timer_start(1000, 'codellama#Fetch')
endfunction

" Fetch function that gathers responses and render text
function! codellama#Fetch(timer)
  echo "fetching " . s:last_timecode
  " Only if normal mode
  if mode() != "n"
    if s:stopped == 0
      call timer_start(1000, 'codellama#Fetch')
    endif
    return
  endif

  " Gather each response from the out file
  let res           = readfile(".codellama.resp")
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
    call timer_start(100, 'codellama#Fetch')
  endif
endfunction

function! codellama#Stop()
  "let s:pid = system("ps x | grep codellama | grep -v grep | awk -F' ' '{print $1}' | tail -1")
  "echo "killed \n"
  call system("touch .codellama.stop")
  let s:stopped = 1
endfunction

function! Max(a,b)
  return a:a > a:b ? a:a : a:b
endfunction

function! Min(a,b)
  return a:a < a:b ? a:a : a:b
endfunction
