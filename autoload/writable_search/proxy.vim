function! writable_search#proxy#New(parent_buffer)
  return {
        \ 'parent_buffer': a:parent_buffer,
        \ 'filename':      '',
        \ 'lines':         [],
        \ 'start_line':    -1,
        \ 'end_line':      -1,
        \
        \ 'Render':       function('writable_search#proxy#Render'),
        \ 'UpdateSource': function('writable_search#proxy#UpdateSource'),
        \ 'UpdateLocal':  function('writable_search#proxy#UpdateLocal'),
        \ 'RenameFile':   function('writable_search#proxy#RenameFile'),
        \ }
endfunction

function! writable_search#proxy#Render() dict
  let header = self.filename . ':' . self.start_line . '-' . self.end_line

  call append(line('$'), header)
  for line in self.lines
    " additional space used for editability
    call append(line('$'), ' '.line)
  endfor
endfunction

" Updates the source file with the new lines given. Adjusts its start and end
" points by the given a:adjustment. Returns the difference in lines in order
" to adjust next proxies.
function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict
  let new_lines = a:new_lines

  " don't do anything if there was no change
  if new_lines == self.lines
    return 0
  endif

  " Adjust given lines
  let self.start_line += a:adjustment
  let self.end_line   += a:adjustment

  " Switch to the source buffer, delete the relevant lines, add the new
  " ones, switch back to the diff buffer.
  let saved_bufhidden = &bufhidden
  let &bufhidden = 'hide'

  exe 'silent edit ' . self.filename
  setlocal nofoldenable

  call cursor(self.start_line, 1)
  if self.end_line - self.start_line >= 0
    silent exe self.start_line . ',' . self.end_line . 'delete _'
  endif
  call append(self.start_line - 1, new_lines)
  silent write
  exe 'silent buffer ' . self.parent_buffer

  let &bufhidden = saved_bufhidden

  " Keep the difference in lines to know how to update the other proxies if
  " necessary.
  let old_line_count = self.end_line - self.start_line + 1
  let new_line_count = len(new_lines)

  let self.end_line = self.start_line + new_line_count - 1
  let self.lines = new_lines " TODO (2013-05-26) Is self.lines necessary?

  return new_line_count - old_line_count
endfunction

function! writable_search#proxy#UpdateLocal() dict
  " Switch to the source buffer and fetch the relevant lines.
  let saved_bufhidden = &bufhidden
  let &bufhidden = 'hide'

  exe 'silent edit ' . self.filename
  setlocal nofoldenable

  let self.lines = getbufline('%', self.start_line, self.end_line)

  exe 'silent buffer ' . self.parent_buffer

  let &bufhidden = saved_bufhidden
endfunction

function! writable_search#proxy#RenameFile(new_filename) dict
  let dirname = fnamemodify(a:new_filename, ':h')

  if !isdirectory(dirname)
    if g:writable_search_confirm_directory_creation
      if confirm(printf('Create directory path "%s"?', dirname))
        call mkdir(dirname, 'p')
      else
        return
      endif
    else
      call mkdir(dirname, 'p')
    endif
  endif

  if rename(self.filename, a:new_filename) == 0
    let self.filename = a:new_filename
  else
    echoerr printf('Couldn''t rename "%s" to "%s"', self.filename, a:new_filename)
    return
  endif
endfunction
