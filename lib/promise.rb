require 'thread'

##
# A delayed-execution promise.  Promises are only executed once.
#
# @example
#   x = promise { factorial 20 }
#   y = promise { fibonacci 10**6 }
#   a = x + 1     # => factorial 20 + 1 after factorial calculates
#   result = promise { a += y }
#   abort ""      # whew, we never needed to calculate y
#
# @example
#   y = 5
#   x = promise { y = y + 5 }
#   x + 5     # => 15
#   x + 5     # => 15
#
# You can pass arguments to be converted to local variables in the block.
#
# @example
#   hello = 'hello'
#   x = promise(hello) { |h| h.capitalize! }
#   puts hello.to_s   # prints 'hello'
#   puts x.to_s       # prints 'Hello'
#
class Promise < defined?(BasicObject) ? BasicObject : ::Object
  NOT_SET = ::Object.new.freeze

  instance_methods.each { |m| undef_method m unless m =~ /^(__.*|object_id)$/ }

  ##
  # Creates a new promise.
  #
  # @example Lazily evaluate a database call
  #   result = promise { @db.query("SELECT * FROM TABLE") }
  #
  # @param  argument_list these will be converted to local variables in the block.
  # @yield  [] The block to evaluate lazily.
  # @see    Kernel#promise
  def initialize(*args,&block)
    ::Kernel.raise ::ArgumentError, "Promise.new requires a block " if block.nil?

    @args = args.collect {|a|begin; a.dup; rescue; a; end}
    raise if block.nil?
    @block  = block
    @mutex  = ::Mutex.new
    @result = NOT_SET
    @error  = NOT_SET
  end

  ##
  # Force the evaluation of this promise immediately
  #
  # @return [Object]
  def __force__
    @mutex.synchronize do
      if @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
        begin
          @result = @block.call(*@args)
        rescue ::Exception => e
          @error = e
        end
      end
    end if @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
    # BasicObject won't send raise to Kernel
    @error.equal?(NOT_SET) ? @result : ::Kernel.raise(@error)
  end
  alias_method :force, :__force__

  ##
  # Does this promise support the given method?
  #
  # @param  [Symbol]
  # @return [Boolean]
  def respond_to?(method)
    :force.equal?(method) || :__force__.equal?(method) || __force__.respond_to?(method)
  end

  private

  def method_missing(method, *args, &block)
    __force__.__send__(method, *args, &block)
  end
end

module Promising
  ##
  # Creates a new promise.
  #
  # @example Lazily evaluate an arithmetic operation
  #   x = promise { 3 + 3 }
  #
  # @param  [obj,...] Arguments to be converted to local variables in the block.
  # @yield       []
  #   A block to be lazily evaluated.
  # @yieldreturn [Object]
  #   The return value of the block will be the lazily evaluated value of the promise.
  # @return      [Promise]
  def promise(*args,&block)
    Promise.new(*args,&block)
  end

  ##
  # Creates a new future.
  #
  # @example Evaluate an operation in another thread
  #   x = future { 3 + 3 }
  #
  # @param  [obj,...] Arguments to be converted to local variables in the block.
  # @yield       []
  #   A block to be optimistically evaluated in another thread.
  # @yield return [Object]
  #   The return value of the block will be the evaluated value of the future.
  # @return      [Promise]
  # @see    Thread#new
  def future(*args, &block)
    t = Thread.start(*args, &block)
    Promise.new{t.value}
  end

  ##
  # Creates a new promise with a worker to be added to a thread pool.
  # The returned worker is a Proc which, when executed, claims the right to process the
  # promised block and begins executing. It can be activated with Proc#call <no arguments>
  #
  # You can add the worker to a thread pool work queue if you want
  # processing to begin immediately (which makes the returned promise behave as a future).
  #
  # For the returned promise, calling Promise#__force__ can yield 3 behaviors:
  #
  # 1. If the worker proc hasn't yet claimed processing, the current thread
  #    will claim it (calling the worker proc at this point will return immediately) and
  #    process it, returning the value.
  # 2. If the worker proc has claimed processing (most likely by being called in another
  #    thread), the curent thread sleeps until the worker proc is done and then returns
  #    the result.
  # 3. If promised block has already finished executing in any thread, the current
  #    thread doesn't need to wait and the result is immediately returned.
  #
  # @example Evaluate an operation in another thread
  #   p, w = promise_with_worker { 3 + 3 }
  #   pool.queue << w      # add the worker to a queue so processing will immediately start
  #   ... later ...
  #   p.__force__          # returns the result with one of the three behaviors listed
  #
  # @param  argument_list these will be converted to local variables in the block.
  # @yield  [] The block to evaluate lazily.
  #   A block to be evaluated in the promise.
  # @return      [Promise, Proc]
  def promise_with_worker(*args,&block)
    p = Promise.new(*args,&block)
    lock = false
    mutex = Mutex.new

    l = lambda { p.__force__ if mutex.synchronize { !lock ? lock = true : false } }
    return Promise.new{ l.call; p.__force__ }, l
  end

end
