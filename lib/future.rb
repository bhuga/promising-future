require 'promise'

##
# A delayed-execution result, optimistically evaluated in a new thread.
#
# @example
#   x = future { sleep 5; 1 + 2 }
#   # do stuff...
#   y = x * 2     # => 6.  blocks unless 5 seconds has passed.
#
class Future < Promise

  ##
  # Creates a new future.
  #
  # @yield  [] The block to evaluate optimistically.
  # @see    Kernel#future
  def initialize(&block)
    super
    # Ruby won't assign the value of @thread until after the thread is off and
    # running, meaning we can run into an unset @thread when joining off in
    # __force__, instead of it being Thread.current.  We could leave it as nil
    # and check for that, but this is a more explicit way to watch for this
    # easy-to-miss gotcha.
    @thread = NOT_SET
    @thread  = ::Thread.new { __force__ }
  end

  ##
  # The value of the future's evaluation.  Blocks until result available.
  #
  # @return [Object]
  def __force__
    @thread.join unless (@thread == ::Thread.current) || @thread.equal?(NOT_SET)
    super
  end
  alias_method :force, :__force__

  
  ##
  # Returns true if klass.equal?(Future), if klass.equal?(Promise), or the
  # underlying block returns an instance of the given klass
  #
  # @param [Class]
  # @return [true, false]
  def is_a?(klass)
    klass.equal?(::Future) || super
  end

  private

end

module Kernel
  ##
  # Creates a new future.
  #
  # @example Evaluate an operation in another thread
  #   x = future { 3 + 3 }
  #
  # @yield       []
  #   A block to be optimistically evaluated in another thread.
  # @yieldreturn [Object]
  #   The return value of the block will be the evaluated value of the future.
  # @return      [Future]
  def future(&block)
    Future.new(&block)
  end
end
