function! igrep#proxy#New(parent_buffer)
  return {
        \ 'parent_buffer': a:parent_buffer,
        \ 'filename':      '',
        \ 'lines':         [],
        \ 'start_line':    -1,
        \ 'end_line':      -1,
        \
        \ 'Render':       function('igrep#proxy#Render'),
        \ 'UpdateSource': function('igrep#proxy#UpdateSource'),
        \ }
endfunction

function! igrep#proxy#Render() dict
  let banner = self.filename . ':' . self.start_line . '-' . self.end_line

  call append(line('$'), '--')
  call append(line('$'), banner)
  call append(line('$'), '--')
  call append(line('$'), self.lines)
endfunction

" Updates the source file with the new lines given. Adjusts its start and end
" points by the given a:adjustment. Returns the difference in lines in order
" to adjust next proxies.
function! igrep#proxy#UpdateSource(new_lines, adjustment) dict
  let new_lines = a:new_lines

  " Adjust given lines
  let self.start_line += a:adjustment
  let self.end_line   += a:adjustment

  " Switch to the source buffer, delete the relevant lines, add the new
  " ones, switch back to the diff buffer.
  let saved_bufhidden = &bufhidden
  let &bufhidden = 'hide'

  exe 'edit ' . self.filename
  setlocal nofoldenable

  call cursor(self.start_line, 1)
  if self.end_line - self.start_line >= 0
    exe self.start_line . ',' . self.end_line . 'delete _'
  endif
  call append(self.start_line - 1, new_lines)
  write
  exe 'buffer ' . self.parent_buffer

  let &bufhidden = saved_bufhidden

  " Keep the difference in lines to know how to update the other proxies if
  " necessary.
  let old_line_count = self.end_line - self.start_line + 1
  let new_line_count = len(new_lines)

  let self.end_line = self.start_line + new_line_count - 1
  let self.lines = new_lines " TODO (2013-05-26) Is self.lines necessary?

  return new_line_count - old_line_count
endfunction
