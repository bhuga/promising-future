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

end
