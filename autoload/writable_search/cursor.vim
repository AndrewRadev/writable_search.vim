" Cursor stack manipulation {{{1
"
" In order to make the pattern of saving the cursor and restoring it
" afterwards easier, these functions implement a simple cursor stack. The
" basic usage is:
"
"   call writable_search#Push()
"   " Do stuff that move the cursor around
"   call writable_search#Pop()

" function! writable_search#Push() {{{2
"
" Adds the current cursor position to the cursor stack.
function! writable_search#cursor#Push()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call add(b:cursor_position_stack, winsaveview())
endfunction

" function! writable_search#Pop() {{{2
"
" Restores the cursor to the latest position in the cursor stack, as added
" from the writable_search#Push function. Removes the position from the stack.
function! writable_search#cursor#Pop()
  if !exists('b:cursor_position_stack')
    let b:cursor_position_stack = []
  endif

  call winrestview(remove(b:cursor_position_stack, -1))
endfunction

" function! writable_search#Peek() {{{2
"
" Returns the last saved cursor position from the cursor stack.
" Note that if the cursor hasn't been saved at all, this will raise an error.
function! writable_search#cursor#Peek()
  return b:cursor_position_stack[-1]
endfunction
