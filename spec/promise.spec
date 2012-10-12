$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
$:.unshift File.dirname(__FILE__)

require 'promise'
require 'shared'

describe Promise do

  before :each do
    @method = Kernel.method(:promise)
  end

  if defined?(BasicObject)
    it "should inherit from BasicObject if available, and not otherwise" do
      Promise.ancestors.should include BasicObject
    end
  end

  it_should_behave_like "A Promise"

  it "should delay execution" do
    value = 5
    x = @method.call { value = 10 ; value }
    value.should == 5
    y = x + 5
    y.should == 15
    value.should == 10
  end

  it "should delay execution of invalid code" do
    lambda {x = [ 1, x / 0 ]}.should raise_error
    lambda {x = [ 1, @method.call { x / 0 }]}.should_not raise_error
  end

  it "promise_with_worker should return a Proc with arity 0" do
    x,w = promise_with_worker{}
    w.class.should == Proc
    w.arity.should == 0
  end

  it "promise_with_worker should work if the worker is ignored" do
    hello = 'hello'
    x,w = promise_with_worker(hello) {|h| h.capitalize! }
    x.should == 'hello'.capitalize
    hello.should == 'hello'
  end

  it "promise_with_worker should share the load between the thread and a thread pool" do
    mutex = Mutex.new
    executing_t = nil;
    
    thread_test = lambda{ mutex.synchronize{executing_t = Thread.current} }

    x,w = promise_with_worker &thread_test
    t = Thread.start{w.call}
    t.join
    executing_t.should == t

    x,w = promise_with_worker &thread_test
    t = Thread.start{x.__force__}
    t.join
    executing_t.should == t

    x,w = promise_with_worker &thread_test
    w.call
    executing_t.should == Thread.current
    
    x,w = promise_with_worker &thread_test
    x.__force__
    executing_t.should == Thread.current

  end

end
