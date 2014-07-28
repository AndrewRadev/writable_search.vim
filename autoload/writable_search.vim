function! writable_search#Start(query, count)
  echo "Searching ..."

  if a:count > 0
    " then we've selected something in visual mode
    let query = shellescape(s:LastSelectedText())
  elseif a:query == ''
    " no pattern is provided, search for the word under the cursor
    let query = expand("<cword>")
  else
    let query = a:query
  end

  if query == ''
    echoerr "No query given"
    return
  endif

  if expand('%') != '' && &filetype != 'writable_search'
    call s:NewBuffer()
  endif

  silent call s:Grep(query)

  if g:writable_search_highlight != ''
    if exists('b:query_highlight_id')
      call matchdelete(b:query_highlight_id)
    endif
    let b:query_highlight_id = matchadd(g:writable_search_highlight, '^\s.*\zs'.query, 0)
  endif

  call writable_search#Parse()
endfunction

function! writable_search#Parse()
  let b:proxies = writable_search#parser#Run()

  if empty(b:proxies)
    echomsg "No results"
    return
  endif

  call writable_search#Render()

  set nomodified
  set filetype=writable_search
endfunction

function! writable_search#Rerun(...)
  if a:0 > 0
    let b:command.extra_flags = a:1
  endif

  %delete _
  call b:command.Read()
  0delete _

  call writable_search#Parse()
endfunction

function! writable_search#Update()
  call writable_search#cursor#Push()
  normal! gg0

  let header_pattern   = '^\S.*$'
  let last_proxy_index = 0
  let proxy_updates    = []

  " Zip up proxies and their new line ranges
  let header_lineno = search(header_pattern, 'Wc')
  while header_lineno > 0
    let header_line          = getline(header_lineno)
    let previous_end_lineno  = header_lineno - 1
    let current_start_lineno = header_lineno + 1

    if len(b:proxies) <= last_proxy_index
      echoerr "Number of patches doesn't add up"
      return
    endif

    if len(proxy_updates) > 0
      let proxy_updates[-1].local_end = previous_end_lineno
    endif

    let [_, filename, start_line, end_line; rest] = matchlist(header_line, '\v^(.*):(\d+)-(\d+)')

    call add(proxy_updates, {
          \ 'proxy':       b:proxies[last_proxy_index],
          \ 'local_start': current_start_lineno,
          \ 'local_end':   -1,
          \ 'filename':    filename,
          \ 'start_line':  str2nr(start_line),
          \ 'end_line':    str2nr(end_line),
          \ })
    let last_proxy_index += 1

    " Jump to the next line for the next search
    exe current_start_lineno
    let header_lineno = search(header_pattern, 'Wc')
  endwhile

  " Update last proxy
  if len(proxy_updates) > 0
    let proxy_updates[-1].local_end = line('$')
  endif

  " Validate that we've got all the proxies and their new lines
  if len(proxy_updates) != len(b:proxies)
    echoerr "Number of patches doesn't add up"
    return
  endif

  for proxy_update in proxy_updates
    if proxy_update.local_end < 0
      echoerr "Error parsing update"
      return
    endif
  endfor

  " Keep a dictionary of changed line counts per filename
  let deltas = {}

  " Keep a dictionary of changed file names
  let renames = {}

  " Perform actual update
  for proxy_update in proxy_updates
    let proxy = proxy_update.proxy

    " adjust for any renames
    if has_key(renames, proxy.filename)
      let proxy.filename = renames[proxy.filename]
    endif

    " collect new lines, removing first whitespace char from view
    let new_lines = []
    for line in getbufline('%', proxy_update.local_start, proxy_update.local_end)
      call add(new_lines, line[1:])
    endfor

    if !has_key(deltas, proxy.filename)
      let deltas[proxy.filename] = 0
    endif
    let deltas[proxy.filename] += proxy.UpdateSource(new_lines, deltas[proxy.filename])

    let proxy.start_line = proxy_update.start_line
    let proxy.end_line   = proxy_update.end_line

    if proxy_update.filename != proxy.filename
      if g:writable_search_confirm_file_rename
        if confirm(printf('Rename "%s" to "%s"?', proxy.filename, proxy_update.filename))
          let renames[proxy.filename] = proxy_update.filename
          call proxy.RenameFile(proxy_update.filename)
        endif
      else
        let renames[proxy.filename] = proxy_update.filename
        call proxy.RenameFile(proxy_update.filename)
      endif
    endif

    call proxy.UpdateLocal()
  endfor

  " Re-render to make changes visible
  call writable_search#Render()
  set nomodified

  call writable_search#cursor#Pop()
endfunction

function! writable_search#Render()
  %delete _
  for proxy in b:proxies
    call proxy.Render()
  endfor
  0delete _
endfunction

function! writable_search#ProxyUnderCursor()
  let cursor_lineno    = line('.')
  let header_pattern   = '^\S.*$'
  let last_proxy_index = -1

  call writable_search#cursor#Push()
  exe 1

  let header_lineno = search(header_pattern, 'Wc')
  while header_lineno > 0 && header_lineno < cursor_lineno
    if len(b:proxies) <= last_proxy_index
      echoerr "Number of patches doesn't add up"
      return
    endif

    let last_proxy_index += 1
    exe (header_lineno + 1)
    let header_lineno = search(header_pattern, 'Wc')
  endwhile

  call writable_search#cursor#Pop()

  return b:proxies[last_proxy_index]
endfunction

function! s:NewBuffer()
  exe g:writable_search_new_buffer_command
endfunction

function! s:Grep(query)
  if g:writable_search_command_type != ''
    let b:command = writable_search#command#New(g:writable_search_command_type, a:query)

    if !b:command.IsSupported()
      unlet b:command
      echoerr "The command type '".g:writable_search_command_type."' is not supported on this system"
      return
    endif
  else
    for possible_command in g:writable_search_backends
      let b:command = writable_search#command#New(possible_command, a:query)

      if b:command.IsSupported()
        break
      else
        unlet b:command
      endif
    endfor
  endif

  if !exists('b:command')
    echoerr "Couldn't find a supported command on the system from: ".join(g:writable_search_backends, ', ')
    return
  endif

  %delete _
  call b:command.Read()
  0delete _
endfunction

function! s:LastSelectedText()
  let saved_cursor = getpos('.')

  let original_reg      = getreg('z')
  let original_reg_type = getregtype('z')

  normal! gv"zy
  let text = @z

  call setreg('z', original_reg, original_reg_type)
  call setpos('.', saved_cursor)

  return text
endfunction
