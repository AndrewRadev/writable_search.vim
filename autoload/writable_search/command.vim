function! writable_search#command#New(type, query)
  return {
        \ 'query':       a:query,
        \ 'type':        a:type,
        \ 'extra_flags': '',
        \
        \ 'Read':        function('writable_search#command#Read'),
        \ 'String':      function('writable_search#command#String'),
        \ 'IsSupported': function('writable_search#command#IsSupported'),
        \ 'FullCommand': function('writable_search#command#FullCommand'),
        \ }
endfunction

function! writable_search#command#Read() dict
  let full_command = self.FullCommand()
  if full_command == ''
    return
  endif

  exe 'r!'.full_command
endfunction

function! writable_search#command#String() dict
  let full_command = self.FullCommand()
  if full_command == ''
    return
  endif

  return full_command
endfunction

function! writable_search#command#FullCommand() dict
  let egrep_command    = 'egrep %s . -R -I -n -H %s'
  let git_grep_command = 'git grep -I -n -H %s %s'
  let ack_command      = 'ack %s --nogroup %s'
  let ag_command       = 'ag %s --nogroup %s'

  if g:writable_search_context_lines
    let flags = '-C'.g:writable_search_context_lines
  else
    let flags = ''
  endif

  if self.extra_flags != ''
    let flags .= ' '.(self.extra_flags)
  endif

  if self.type == 'egrep'
    let full_command = printf(egrep_command, self.query, flags)
  elseif self.type == 'ack'
    let full_command = printf(ack_command, self.query, flags)
  elseif self.type == 'ag'
    let full_command = printf(ag_command, self.query, flags)
  elseif self.type == 'git-grep'
    let full_command = printf(git_grep_command, flags, self.query)
  elseif self.type == 'ack.vim'
    let ackprg = g:ackprg
    let ackprg = substitute(ackprg, '--column', '', '')

    let full_command = ackprg.' '.self.query.' --nogroup '.flags
  else
    echoerr "Unknown value for g:writable_search_command_type:  "
          \ .g:writable_search_command_type
          \ .". Needs to be one of 'git-grep', 'egrep', 'ack', 'ack.vim', 'ag'"
    return ''
  endif

  return full_command
endfunction

function! writable_search#command#IsSupported() dict
  if self.type == 'git-grep'
    return s:ExecutableExists('git') && s:InGitRepo()
  elseif self.type == 'ack.vim'
    return exists('g:ackprg')
  elseif self.type == 'ack'
    return s:ExecutableExists('ack')
  elseif self.type == 'egrep'
    return s:ExecutableExists('egrep')
  endif
endfunction

function! s:InGitRepo()
  let path_components = split(getcwd(), '/')

  for index in range(len(path_components), 0, -1)
    let path = '/'.join(path_components[0:index], '/')

    if glob(path.'/.git', 1) != ''
      return 1
    endif
  endfor

  return 0
endfunction

function! s:ExecutableExists(executable)
  call system('which '.a:executable)
  return !v:shell_error
endfunction
