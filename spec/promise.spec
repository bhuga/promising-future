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

  it "should not be forced on creation" do
    x = @method.call { 3 + 5 }
    x.__forced?.should be_false
  end

  it "should be a Promise without executing the block" do
    y = 1
    x = @method.call { y = y + 1 }
    x.is_a?(::Promise).should be_true
    y.should == 1
  end

  it_should_behave_like "A Promise"

  it "should delay execution" do
    value = 5
    x = @method.call { value = value + 5}
    value.should == 5
    x.__force__
    value.should == 10
  end

  it "should delay execution of invalid code" do
    lambda {x = [ 1, x / 0 ]}.should raise_error
    lambda {x = [ 1, @method.call { x / 0 }]}.should_not raise_error
  end

end
