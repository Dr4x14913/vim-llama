
function! codellama#Start()
  let s:codellama_end_append    = 0
  let s:codellama_start_line    = line(".")
  let s:stopped                 = 0
  let context                   = join(getline(Max(line(".") - g:codellama_context_size, 2), line(".")), "\n")
  let s:run_script              = expand('<sfile>:p:h:h') . "/codellama/scripts/run_codellama.sh"
  let cmd                       = s:run_script . " &"

  call system("echo '" . context . "' > .codellama.ctx")
  call system("echo '" . cmd . "' > .codellama.cmd")
  call system(cmd)
  call setreg("a", "")
  call timer_start(1000, 'codellama#Fetch')
endfunction

function! codellama#Fetch(timer)
  "only if normal mode
  if mode() != "n"
    if s:stopped == 0
      call timer_start(1000, 'codellama#Fetch')
    endif
    return
  endif

  let res       = system("cat .codellama.resp")
  let splitted  = split(res, "\n")
  let filtered  = splitted[index(splitted, "DOCKER IS READY")+2:]
  call setreg("a", join(filtered, "\n"), "v")

  let s:startline = s:codellama_start_line + 1
  if s:startline <= s:codellama_end_append
    call cursor(s:startline, 0)
    for i in range(1, s:codellama_end_append - s:startline + 1)
      exec "normal! dd"
    endfor
  endif

  echo "continue"
  let s:append_index = 0
  for line in filtered
    call cursor(s:codellama_start_line + s:append_index, 0)
    exec "normal! o<ESC>"
    call setline(line("."), line)
    let s:append_index = s:append_index + 1
  endfor
  let s:codellama_end_append = line(".")

  if s:stopped == 0
    let s:stopped = system("ls -al | grep .codellama.stopped | wc -l")
    call timer_start(1000, 'codellama#Fetch')
  endif
endfunction

function! codellama#Stop()
  let s:pid = system("ps x | grep codellama | grep -v grep | awk -F' ' '{print $1}' | tail -1")
  echo system("kill -9 " . s:pid)
  echo "killed " . s:pid ."\n"
  let s:stopped = 1
endfunction

function! Max(a,b)
  return a:a > a:b ? a:a : a:b
endfunction

function! Min(a,b)
  return a:a < a:b ? a:a : a:b
endfunction


