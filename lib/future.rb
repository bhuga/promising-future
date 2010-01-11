require 'promise'

##
# A delayed-execution result, optimistcally evaluated in a new Thread.
# @example
#     x = future { sleep 5; 1 + 2 }
#     # do stuff...
#     y = x * 2     # => 6.  blocks unless 5 seconds has passed.
# 
class Future
  
  instance_methods.each { |m| undef_method m unless m =~ /__/ }

  ##
  # @param [Proc] block
  # @return [Future]
  def initialize(block)
    @promise = promise &block
    @thread = Thread.new do
      @promise.force
    end
  end

  ##
  # The value of the future's evaluation.  Blocks until result available.
  # @return [Any]
  def force
    @thread.join
    @promise
  end

  # @private
  def method_missing(method, *args, &block)
    @promise.send(method, *args, &block) 
  end


end


module Kernel

  # Create a new future 
  # @example
  #     x = future { 3 + 3 }
  def future(&block)
    Future.new(block)
  end

end
