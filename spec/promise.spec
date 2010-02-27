$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'promise'

describe Promise do

  it "should be createable" do
    lambda {x = promise { 3 + 5 }}.should_not raise_error
  end

  it "should not accept a promise requiring arguments" do
    lambda {x = promise { | x | 3 + 5 }}.should raise_error
  end

  it "should delay execution" do
    value = 5
    x = promise { value = 10 ; value }
    value.should == 5
    y = x + 5
    y.should == 15
    value.should == 10
  end

  it "should delay execution of invalid code" do
    lambda {x = [ 1, x / 0 ]}.should raise_error
    lambda {x = [ 1, promise { x / 0 }]}.should_not raise_error
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

  it "should remain the same for an object reference" do
    h = {}
    x = Object.new
    h[:test] = promise { x }
    h[:test].should == x
  end

  it "should maintain eql?-ity for the result of a promise" do
    x = Object.new
    y = promise { x }
    x.should eql y
  end

  it "should maintain equal?-ity for the result of a promise" do
    x = Object.new
    y = promise { x }
    x.should equal y
  end

  it "should be thread safe" do
    x = promise { res = 1; 3.times { res = res * 5 ; sleep 1 } ; res}
    threads = []
    results = []
    changeds = []
    10.times do
      threads << Thread.new do
        changed = false
        res = old_res = 125
        10.times do |i|
          old_res = res
          res = x + 5
          changed ||= res != old_res && i != 0
          sleep 0.3
        end
        results << res
        changeds << changed
      end
    end
    threads.each do |t|
      t.join
    end
    results.each do |result|
      result.should == 130
    end
    changeds.each do |changed|
      changed.should == false
    end
    changeds.size.should == 10
  end

end

