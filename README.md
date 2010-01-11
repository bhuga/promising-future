# Promising Future
A glimpse of a promising future in which ruby supports delayed execution

## Overview

    require 'promise'
    require 'future'    # can just require future if using both

    x = promise { 1 + 2 }
    y = future  { sleep 10; 5 + 5 }

    puts x      # => 3
    # ... do work for 5 seconds
    puts y      # => 10, after blocking 5 seconds

Promises and futures both transparantly delay the execution of a block.
Futures run the evaluation of the block optimistically in another thread.

## Classes

 * {Promise}
 * {Future}

## Author
Ben Lavender (http://github.com/bhuga)

## Unlicense
Promising Future is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.
