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

  it "should be thread safe" do
    x = promise { res = 1; 3.times { res = res * 5 ; sleep 1 } ; res}
    threads = []
    results = []
    10.times do
      threads << Thread.new do
        changed = false
        res = 125
        10.times do
          old_res = res
          res = x + 5
          changed = true if res != old_res
          sleep 0.3
        end
        results << res
      end
    end
    threads.each do |t|
      t.join
    end
    results.each do |result|
      result.should == 130
    end
  end

end

