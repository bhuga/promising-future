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

  instance_methods.each { |m| undef_method m unless m =~ /^(__.*|object_id)$/ }

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
      ::Kernel.raise ::ArgumentError, "Cannot store a promise that requires an argument"
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
  # @param  [Symbol, Boolean]
  # @return [Boolean]
  def respond_to?(method, include_all=false)
    # If the promised object implements marshal_dump, Marshal will use it in
    # preference to our _dump, so make sure that doesn't happen.
    return false if :marshal_dump.equal?(method)

    :_dump.equal?(method) ||  # for Marshal
      :force.equal?(method) ||
      :__force__.equal?(method) ||
      __force__.respond_to?(method, include_all)
  end

  ##
  # Method used by Marshal to serialize the object.  Forces evaluation.
  #
  # @param  [Integer] limit -- refer to Marshal doc
  # @return [Object]
  def _dump(limit)
    ::Marshal.dump(__force__, limit)
  end

  ##
  # Method used by Marshal to deserialize the object.
  #
  # @param  [Object]
  # @return [Promise]
  def self._load(obj)
    ::Marshal.load(obj)
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
