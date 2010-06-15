# Promising Future
A glimpse of a promising future in which Ruby supports lazy evaluation.

## Overview
[Promises and futures][] both transparently defer the execution of a block.
Promises evaluate the given block if and when its result is first needed.
Futures evaluate the given block optimistically in another thread.

    require 'promise'
    require 'future'    # you can just require 'future' if using both
    
    x = promise { 1 + 2 }
    y = future  { sleep 10 && 6 * 7 }
    
    puts x      #=> 3
    sleep 5     # ... do work for 5 seconds ...
    puts y      #=> 42, after blocking 5 seconds

Note that this is pretty useless in Ruby's interactive shell `irb`, as it
will eagerly evaluate everything as part of its read-eval-print loop,
forcing promises and futures to yield their results.

The library has been tested with Ruby 1.8.7, 1.9.1 and JRuby 1.5.0.
YARD documentation is available at <http://promise.rubyforge.org/>

## Classes

 * {Promise}
 * {Future}

## Installation
The library is distributed via [RubyGems](http://rubygems.org/):

    $ gem install promise

## Source
The source is available at <http://github.com/bhuga/promising-future>

## Author
[Ben Lavender](http://github.com/bhuga)

## Unlicense
Promising Future is free and unencumbered public domain software. For more
information, see <http://unlicense.org/> or the accompanying UNLICENSE file.

[Promises and futures]: http://en.wikipedia.org/wiki/Futures_and_promises
