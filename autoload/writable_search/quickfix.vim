function! writable_search#quickfix#Start()
  let ordered_filenames = []
  let file_lines = {}
  let context_lines = g:writable_search_context_lines

  for entry in getqflist()
    let filename = bufname(entry.bufnr)
    call add(ordered_filenames, filename)

    if !has_key(file_lines, filename)
      let file_lines[filename] = []
    endif

    let start = max([entry.lnum - context_lines, 1])
    let end = entry.lnum + context_lines

    call add(file_lines[filename], [start, end])
  endfor

  let ordered_filenames = s:SortUniq(ordered_filenames)

  for [filename, segments] in items(file_lines)
    let file_lines[filename] = s:MergeLineSegments(segments)
  endfor

  let proxies = []

  call writable_search#InitBuffer()

  for filename in ordered_filenames
    let segments = file_lines[filename]
    let file_contents = readfile(filename)

    for segment in segments
      let [start_line, end_line] = segment

      let start_index = start_line - 1
      let end_index   = end_line - 1

      " truncate end index to the length of the file
      if end_index >= len(file_contents)
        let end_index = len(file_contents) - 1
      endif

      let current_proxy = writable_search#proxy#New(bufnr('%'))

      let current_proxy.filename   = filename
      let current_proxy.lines      = file_contents[start_index:end_index]
      let current_proxy.start_line = start_index + 1
      let current_proxy.end_line   = end_index + 1

      call add(proxies, current_proxy)
    endfor
  endfor

  let b:proxies = proxies
  call writable_search#Render()

  set nomodified
  set filetype=writable_search
endfunction

" Given a list of [start, end] pairs, merges pairs whose contexts overlap
function! s:MergeLineSegments(segments)
  let i = 0
  let segments = a:segments
  call sort(segments)
  let merged_segments = []

  while i < len(segments)
    let segment = segments[i]
    let i += 1

    if i >= len(segments)
      " no next one, just add this one and quit
      call add(merged_segments, segment)
      break
    endif

    let next_segment = segments[i]

    while segment[1] >= next_segment[0]
      " the segments overlap, merge them and take the next one until they
      " don't
      let segment = [segment[0], next_segment[1]]
      let i += 1

      if i >= len(segments)
        break
      endif

      let next_segment = segments[i]
    endwhile

    call add(merged_segments, segment)
  endwhile

  return merged_segments
endfunction

function! s:SortUniq(list)
  if exists('*uniq')
    return uniq(sort(copy(a:list)))
  else
    let index = {}
    for entry in a:list
      let index[entry] = 1
    endfor
    return sort(keys(index))
  endif
endfunction
