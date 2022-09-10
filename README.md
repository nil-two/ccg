ccg
===

Play circle cross game.

```
$ ccg
     Circle Cross Game

           #####
Circle:  0 #   # Circle (Turn)
           #   #
 Cross:  0 #   # Cross
           #####

     (Press q to quit)
```

Usage
-----

```
$ ccg [<option(s)>]
play circle cross game.

options:
      --help   print usage and exit

keys:
  ... in game ...
  h    <Left>    move cursor to left
  j    <Down>    move cursor to bottom
  k    <Up>      move cursor to top
  l    <Right>   move cursor to right
  <CR> <Space>   mark cell
  ... in result ...
  h    <Left>    toggle continuation
  l    <Right>   toggle continuation
  <CR> <Space>   select continuation
  ... in all ...
  q              finish game and exit
  <C-c>          finish game (for debug)
```

Requirements
------------

- Bash
- Vim

Installation
------------

1. Copy `ccg` into your `$PATH`.
2. Make `ccg` executable.

```
$ curl -L https://raw.githubusercontent.com/nil-two/ccg/master/ccg > ~/bin/ccg
$ chmod +x ~/bin/ccg
```

Note: In this example, `$HOME/bin` must be included in `$PATH`.

Options
-------

### --help

Print usage and exit.

```
$ ad --help
(Print usage)
```

License
-------

MIT License

Author
------

nil2 <nil2@nil2.org>
