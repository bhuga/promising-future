$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))

require 'future'
require 'time'

describe Future do

  if defined?(BasicObject)
    it "should inherit from BasicObject if available, and not otherwise" do
      Future.ancestors.should include BasicObject
    end
  end

  it "should be createable" do
    lambda {x = future { 3 + 5 }}.should_not raise_error
  end

  it "should not accept a future requiring arguments" do
    lambda {x = future { | x | 3 + 5 }}.should raise_error
  end

  it "should be forceable" do
    x = future { 3 + 5 }
    x.force.should == 8
    x.should == 8
  end

  it "should evaluate to a value" do
    (5 + future { 1 + 2 }).should == 8
  end

  it "should hold its value" do
    y = 5
    x = future { y = y + 5 }
    x.should == 10
    x.should == 10
  end

  it "should work in the background" do
    start = Time.now
    x = future { sleep 3; 5 }
    middle = Time.now
    y = x + 5
    y.should == 10
    finish = Time.now
    (middle - start).should be_close 0, 10**-3
    (finish - start).should be_close 3, 10**-3
  end

  it "should be thread safe" do
    x = future { res = 1; 3.times { res = res * 5 ; sleep 1 } ; res}
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

