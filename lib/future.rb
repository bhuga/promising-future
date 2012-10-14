##
# A delayed-execution result, optimistically evaluated in a new thread.
#
# @example
#   x = future { sleep 5; 1 + 2 }
#   # do stuff...
#   y = x * 2     # => 6.  blocks unless 5 seconds has passed.
#
# You can pass arguments to be converted to local variables in the block.
#
# @example
#   hello = 'hello'
#   x = future(hello) { |h| h.capitalize! }
#   puts hello.to_s   # prints 'hello'
#   puts x.to_s       # prints 'Hello'
#
class Future < defined?(BasicObject) ? BasicObject : Object
  instance_methods.each { |m| undef_method m unless m =~ /^(__.*|object_id)$/ }

  ##
  # Creates a new future.
  #
  # @param  argument_list these will be converted to local variables in the block.
  # @yield  [] The block to evaluate optimistically.
  # @see    Kernel#future
  def initialize(*args, &block)
    @thread  = ::Thread.new(*args,&block)
  end

  ##
  # The value of the future's evaluation.  Blocks until result available.
  #
  # @return [Object]
  def __force__
    unless @thread.nil?
      @value = @thread.value
      @thread = nil
    end
    @value
  end
  alias_method :force, :__force__

  ##
  # Does this future support the given method?
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
