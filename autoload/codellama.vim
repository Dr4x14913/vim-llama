
function! codellama#Start()
  call NewEmptyLine()

  let s:start_line              = line(".")
  let s:last_ended              = line(".")
  let s:cur_buf                 = bufnr("%")
  let s:last_timecode           = 0
  let s:stopped                 = 0
  let context                   = join(getline(Max(line(".") - g:codellama_context_size, 1), line(".")), "\n")
  let s:run_script              = "~/projects/vim-llama/scripts/run_codellama.py"
  let cmd                       = s:run_script . " &"

  if filereadable(expand(s:run_script)) == 0
    echo "Cant find run_codellama.sh script in " . s:run_script
    return
  endif

  call system("echo '" . context . "' > .codellama.ctx")
  call system("echo '" . cmd . "' > .codellama.cmd")
  call system(cmd)
  call timer_start(1000, 'codellama#Fetch')
endfunction

function! codellama#Fetch(timer)
  echo "fetching " . s:last_timecode
  "only if normal mode
  if mode() != "n"
    if s:stopped == 0
      call timer_start(1000, 'codellama#Fetch')
    endif
    return
  endif

  let res           = readfile(".codellama.resp")
  let string_to_add = ""
  let s:register    = 0
  for j in res
    try
      let obj = json_decode(j)
    catch
      break
    endtry
    let s:timecode = get(obj, "created_at")
    let s:done     = get(obj, "done")
    if s:done
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

  if len(string_to_add) > 0
    call bufload(s:cur_buf)
    let s:first = 1
    for line in split(string_to_add, "\n", 1)
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
    call timer_start(500, 'codellama#Fetch')
  endif
endfunction

function! codellama#Stop()
  "let s:pid = system("ps x | grep codellama | grep -v grep | awk -F' ' '{print $1}' | tail -1")
  call system("touch .codellama.stop")
  echo "killed \n"
  let s:stopped = 1
endfunction

function! Max(a,b)
  return a:a > a:b ? a:a : a:b
endfunction

function! Min(a,b)
  return a:a < a:b ? a:a : a:b
endfunction

function! NewEmptyLine()
  call append(line("."), "")
  call cursor(line(".") + 1, 0)
endfunction
