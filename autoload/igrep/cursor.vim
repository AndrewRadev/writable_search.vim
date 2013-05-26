" Cursor stack manipulation {{{1
"
" In order to make the pattern of saving the cursor and restoring it
" afterwards easier, these functions implement a simple cursor stack. The
" basic usage is:
"
"   call igrep#Push()
"   " Do stuff that move the cursor around
"   call igrep#Pop()

" function! igrep#Push() {{{2
"
" Adds the current cursor position to the cursor stack.
function! igrep#cursor#Push()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call add(b:cursor_position_stack, winsaveview())
endfunction

" function! igrep#Pop() {{{2
"
" Restores the cursor to the latest position in the cursor stack, as added
" from the igrep#Push function. Removes the position from the stack.
function! igrep#cursor#Pop()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call winrestview(remove(b:cursor_position_stack, -1))
endfunction

" function! igrep#Peek() {{{2
"
" Returns the last saved cursor position from the cursor stack.
" Note that if the cursor hasn't been saved at all, this will raise an error.
function! igrep#cursor#Peek()
  return b:cursor_position_stack[-1]
endfunction
