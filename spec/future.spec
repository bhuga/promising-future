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
      expect(Future.ancestors).to include BasicObject
    end
  end

  it_should_behave_like "A Promise"

  it "should work in the background" do
    start = Time.now
    x = future { sleep 3; 5 }
    middle = Time.now
    y = x + 5
    expect(y).to eq 10
    finish = Time.now
    expect(middle - start).to be_within(10**-2).of(0)
    expect(finish - start).to be_within(10**-2).of(3)
  end

  it "should finished when timeout" do
    # timeout
    x = future(timeout:1){ sleep 2; 5 }
    expect{x + 5}.to raise_error(::Timeout::Error)

    # not timeout
    x = future(timeout:2){ sleep 1; 5 }
    expect(x + 5).to eq 10
  end
end

