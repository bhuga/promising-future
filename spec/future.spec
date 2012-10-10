$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
$:.unshift File.dirname(__FILE__)

require 'future'
require 'time'
require 'shared'

describe Future do

  before :each do
    @method = Kernel.method(:future)
  end

  if defined?(BasicObject)
    it "should inherit from BasicObject if available, and not otherwise" do
      Future.ancestors.should include BasicObject
    end
  end

  it_should_behave_like "A Promise"

  it "should work in the background" do
    start = Time.now
    x = future { sleep 3; 5 }
    middle = Time.now
    y = x + 5
    y.should == 10
    finish = Time.now
    (middle - start).should be_within(10**-2).of(0)
    (finish - start).should be_within(10**-2).of(3)
  end

end

