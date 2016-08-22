Note: This plugin works on Unix-based systems, but probably doesn't work on
Windows.

## Usage

The plugin exposes the command `:WritableSearch`, which takes a search query
and performs a grep (or ack, or a different search command -- see the
`Compatibility` section), with that query. For example:


``` vim
:WritableSearch Server
```

![screenshot](http://i.andrewradev.com/dd454391f2105569cd90006aa5638c80.png)

The results are opened in a new tab (by default), and are very similar to what
you would get from performing the search on the command-line. The difference is
that you can now edit this buffer and, upon writing, the original files will be
updated with the changes.

This gives you a very simple and straightforward search-and-replace process.
However, read this document to the end for some important gotchas.

If you change the filenames in the header blocks, those files will be renamed
(with some manual confirmation that you can turn off if you're feeling
adventurous). For example, if the header says:

```
foo/bar.txt:12-34
```

and you change that to:

```
foo/renamed.txt:12-34
```

Then the file `foo/bar.txt` will be renamed to `foo/renamed.txt`. If this is
not possible, you'll get an error.

If you change the line numbers displayed in the headers, the virtual "window"
that this search result is pointing to will reposition itself to those line
numbers. For example, if the header says:

```
foo/bar.txt:12-34
```

and you change that to:

```
foo/bar.txt:10-22
```

Then the lines displayed will now be the ones from 10 to 22.

The command `:Rerun` defined in the search buffer can be used to perform the
last search again, with additional flags. For example:

``` vim
:WritableSearch function_call\(
:Rerun -C1
```

If you call the `:WritableSearch` command with no arguments, it will take the
word under the cursor and search for that. If you call it while having marked
something in visual mode (with `:'<,'>WritableSearch`), it will use the
current visual selection as the search query.

### Quickfix support

If you've already run any form of grep with the results loaded in the quickfix window, you can easily create a WritableSearch buffer with the contents of the quickfix list by running the `:WritableSearchFromQuickfix` command.

If you do this often, you might want to create a buffer-local mapping for quickfix buffers by editing the file `ftplugin/qf.vim` and creating the mapping like so:

``` vim
nnoremap <buffer> <leader>ws :WritableSearchFromQuickfix
```

### Important

- Notice that each piece of code has been indented with a single extra
  space. This has been done to make parsing the results possible and you
  should never put anything in column 1 yourself.

- You should never delete a result item yourself, or add new ones. The
  parser will get confused and error out.

### Backends

By default, the plugin attempts to find the "best" search mechanism that can
work. It tries to use `git-grep` if you're in a git directory, `ack.vim` if
the plugin is available, and so on. It falls back to `egrep` as the final
resort.

This is encoded in the variable `g:writable_search_backends`, which holds a
list of all the types of searches that will be attempted. See its documentation
for details, but here's a short summary of the possible items, in their default
ordering:

- `git-grep`, only in a git repository.
- `ack.vim`, relying on the [ack.vim](https://github.com/mileszs/ack.vim)
  plugin. This simply takes the `g:ackprg` variable and tries to re-use it. It
  may not work correctly depending on what you've set it to. It only works if
  the `g:ackprg` variable is detected.
- `ack`, using the perl [ack](http://beyondgrep.com/) tool, only works if the
  tool is installed.
- `egrep`, the last resort. Slow, but should always be present on a *nix system

So, if you want to use only `ack.vim` and fall back to `egrep` if the `ack`
program is not installed, you would put this in your `~/.vimrc`:

``` vim
let g:writable_search_backends = ['ack.vim', 'egrep']
```

The plugin could also use `ag` (or it could use `ag` through `ack.vim`), but
right now, there are some problems with it when dealing with matches at the
ends of files. It's recommended to stick to `ack` or `egrep`.

### Advanced

If you want to plug in your own, potentially complicated search expression,
and have the plugin make it writable for you, you can put the results in a
buffer and invoke the parsing function directly:

``` vim
:call writable_search#Parse()
```

This will try to parse the contents of the buffer and turn them into a
writable_search buffer. However, the format must be the same as the output of
grep with the options "-n/--line-number" and "-H/--with-filename". This looks
like this:

```
<filename>-<line>-<text...>
<filename>:<line>:<text with a match...>
<filename>-<line>-<text...>
--
<filename>:<line>:<text with a match...>
```

An example:

```
autoload/writable_search/proxy.vim-26-" to adjust next proxies.
autoload/writable_search/proxy.vim:27:function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict
autoload/writable_search/proxy.vim-28-  let new_lines = a:new_lines
--
autoload/writable_search/parser.vim:1:function! writable_search#parser#Run()
autoload/writable_search/parser.vim-2-  let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
--
autoload/writable_search/parser.vim-25-  for lines in a:grouped_lines
autoload/writable_search/parser.vim:26:    let current_proxy          = writable_search#proxy#New(bufnr('%'))
autoload/writable_search/parser.vim-27-    let current_proxy.filename = s:FindFilename(lines)
```

The resulting writable_search buffer for this example would look like so:

```
autoload/writable_search/proxy.vim:26-28
 " to adjust next proxies.
 function! writable_search#proxy#UpdateSource(new_lines, adjustment) dict
   let new_lines = a:new_lines
autoload/writable_search/parser.vim:1-2
 function! writable_search#parser#Run()
   let grouped_lines = s:PartitionLines(getbufline('%', 1, '$'))
autoload/writable_search/parser.vim:25-27
   for lines in a:grouped_lines
     let current_proxy          = writable_search#proxy#New(bufnr('%'))
     let current_proxy.filename = s:FindFilename(lines)
```

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/writable_search.vim/blob/master/CONTRIBUTING.md) first for some guidelines.
