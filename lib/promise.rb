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
class Promise < defined?(BasicObject) ? BasicObject : ::Object
  NOT_SET = ::Object.new.freeze

  instance_methods.each { |m| undef_method m unless m.to_s =~ /__/ }

  ##
  # Creates a new promise.
  #
  # @example Lazily evaluate a database call
  #   result = promise { @db.query("SELECT * FROM TABLE") }
  #
  # @yield  [] The block to evaluate lazily.
  # @see    Kernel#promise
  def initialize(&block)
    if block.arity > 0
      raise ArgumentError, "Cannot store a promise that requires an argument"
    end
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
          @result = @block.call
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
  # @return [true, false]
  def respond_to?(method)
    :__forced?.equal?(method) || :force.equal?(method) || :__force__.equal?(method) || __force__.respond_to?(method)
  end

  ##
  # Returns true if klass.equal?(Promise) or the underlying block returns an
  # instance of the given klass
  #
  # @param [Class]
  # @return [true, false]
  def is_a?(klass)
    klass.equal?(::Promise) || __force__.is_a?(klass)
  end

  ##
  # Returns true if this promise has finished executing
  #
  # @return [true, false]
  def __forced?
    !(@result.equal?(NOT_SET) && @error.equal?(NOT_SET))
  end

  private

  def method_missing(method, *args, &block)
    __force__.__send__(method, *args, &block)
  end
end

module Kernel
  ##
  # Creates a new promise.
  #
  # @example Lazily evaluate an arithmetic operation
  #   x = promise { 3 + 3 }
  #
  # @yield       []
  #   A block to be lazily evaluated.
  # @yieldreturn [Object]
  #   The return value of the block will be the lazily evaluated value of the promise.
  # @return      [Promise]
  def promise(&block)
    Promise.new(&block)
  end
end
