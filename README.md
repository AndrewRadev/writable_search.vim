*Note: very experimental (but usable) at this point, some more documentation
soon to come.*

## Usage

The plugin exposes the command `WritableSearch`, which takes an argument and
some optional command-line flags, and performs a grep (or ack, or any other
search command), with the given parameters. For example:

``` vim
:WritableSearch function_call\( -C5
```

The results are opened in a new window, and are very similar to what you would
get from performing the search on the command-line. The difference is that you
can now edit this buffer and, upon writing, the original files will be updated
with the changes. This gives you a very simple and straightforward
search-and-replace process.

The command `:Rerun` defined in the search buffer can be used to perform the
search again, with different flags. For example:
``` vim
:WritableSearch function_call\( -C5
:Rerun -C1
```

## Contributing

Pull requests are welcome, but take a look at [CONTRIBUTING.md](https://github.com/AndrewRadev/writable_search.vim/blob/master/CONTRIBUTING.md) first for some guidelines.
