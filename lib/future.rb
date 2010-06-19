require 'promise'

##
# A delayed-execution result, optimistcally evaluated in a new Thread.
# @example
#     x = future { sleep 5; 1 + 2 }
#     # do stuff...
#     y = x * 2     # => 6.  blocks unless 5 seconds has passed.
#
class Future < defined?(BasicObject) ? BasicObject : Object

  instance_methods.each { |m| undef_method m unless m =~ /__/ } unless defined?(BasicObject)

  ##
  # Create a new future
  #
  # @yield [] The block to evaluate optimistically
  # @return [Future]
  def initialize(block)
    @promise = promise &block
    @thread = ::Thread.new do
      @promise.force
    end
  end

  ##
  # The value of the future's evaluation.  Blocks until result available.
  #
  # @return [Any]
  def __force__
    @thread.join
    @promise
  end
  alias_method :force, :__force__

  # @private
  def method_missing(method, *args, &block)
    @promise.send(method, *args, &block)
  end


end


module Kernel

  # Create a new future
  #
  # @example Evaluate an operation in another thread
  #     x = future { 3 + 3 }
  # @return       [Future]
  # @yield        [] A block to be optimistically evaluated in another thread
  # @yieldreturn  [Any] The return value of the block will be the evaluated value of the future. 
  def future(&block)
    Future.new(block)
  end

end
