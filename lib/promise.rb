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
    @args   = args.collect {|a|begin; a.dup; rescue; a; end}
    @mutex  = ::Mutex.new
    @block  = block
    @result = NOT_SET
    @error  = NOT_SET
  end

  ##
  # Creates a worker to be added to a thread pool.
  # The returned worker is a Proc which, when executed, claims the right to process the
  # promised block and begins executing. It can be activated with Proc#call
  #
  # You can add the worker to a thread pool work queue if you want the promise
  # to begin executing in the pool.
  #
  # Promise#__force__ will still wait until the promised block has finished executing, whether
  # by the thread pool or the current thread.
  #
  # @example Evaluate an operation in another thread
  #   p = promise { 3 + 3 }
  #   pool.queue << p.__worker__ # add the worker to a queue so processing will immediately start
  #   ... later ...
  #   p.__force__
  #
  # @return      [Proc]
  def __worker__
    lambda do
       next if !@mutex.try_lock
       __call_block__
       @mutex.unlock
    end
  end

  ##
  # Force the evaluation of this promise immediately
  #
  # @return [Object]
  def __force__
    @mutex.synchronize do
      __call_block__
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
  
  def __call_block__
    return unless @result.equal?(NOT_SET) && @error.equal?(NOT_SET)
    begin
      @result = @block.call(*@args)
    rescue ::Exception => e
      @error = e
    end
    @block = @args = nil # remove references for GC
  end
end

module Kernel
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
  # @yieldreturn [Object]
  #   The return value of the block will be the evaluated value of the future.
  # @return      [Future]
  # @see    Thread#new
  def future(*args, &block)
    t = Thread.start(*args,&block)
    Promise.new { t.value }
  end
end
