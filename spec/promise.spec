$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'promise'

describe Promise do

  it "should be createable" do
    lambda {x = promise { 3 + 5 }}.should_not raise_error
  end

  it "should not accept a promise requiring arguments" do
    lambda {x = promise { | x | 3 + 5 }}.should raise_error
  end

  it "should be forceable" do
    x = promise { 3 + 5 }
    x.force.should == 8
    x.should == 8
  end

  it "should evaluate to a value" do
    (5 + promise { 1 + 2 }).should == 8
  end

  it "should hold its value" do
    y = 5
    x = promise { y = y + 5 }
    x.should == 10
    x.should == 10
  end

end

