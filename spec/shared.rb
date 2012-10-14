require 'rspec'
require 'promise'

shared_examples_for "A Promise" do

  it "should be createable" do
    lambda {x = @method.call { 3 + 5 }}.should_not raise_error
  end

  it "should capture values passed in the args" do
    hello = 'hello'
    x = @method.call(hello) { |h| h.capitalize! }
    hello.should == 'hello'
    x.should == 'hello'.capitalize
  end

  it "should share values not passed in the args" do
    hello = 'hello'
    x = @method.call { hello.capitalize! }
    x.should == 'hello'.capitalize
    hello.should == 'hello'.capitalize
  end

  it "should be forceable" do
    x = @method.call { 3 + 5 }
    x.__force__.should == 8
    x.should == 8
  end

  it "should respond_to? force" do
    x = @method.call { 3 + 5 }
    x.respond_to?(:force).should be_true
  end

  it "should respond_to? __force__" do
    x = @method.call { 3 + 5 }
    x.respond_to?(:__force__).should be_true
  end

  it "should respond_to? a method on the result" do
    x = @method.call { 3 + 5 }
    x.respond_to?(:+).should be_true
  end

  it "should not respond_to? a method not on the result" do
    x = @method.call { 3 + 5 }
    x.respond_to?(:asdf).should be_false
  end

  it "should evaluate to a value" do
    (5 + @method.call { 1 + 2 }).should == 8
  end

  it "should hold its value" do
    y = 5
    x = @method.call { y = y + 5 }
    x.should == 10
    x.should == 10
  end

  it "should only execute once" do
    y = 1
    x = @method.call { (y += 1) && false }
    x.should == false
    x.should == false
    y.should == 2
  end

  it "should raise exceptions raised during execution when accessed" do
    y = Object.new
    y = @method.call { 1 / 0 }
    lambda { y.inspect }.should raise_error ZeroDivisionError
    lambda { y.inspect }.should raise_error ZeroDivisionError
  end

  it "should only execute once when execptions are raised" do
    y = 1
    x = @method.call { (y += 1) && (1 / 0) }
    lambda { x.inspect }.should raise_error ZeroDivisionError
    lambda { x.inspect }.should raise_error ZeroDivisionError
    y.should == 2
  end

  it "should remain the same for an object reference" do
    h = {}
    x = Object.new
    h[:test] = @method.call { x }
    h[:test].should == x
  end

  it "should be eql? for results" do
    x = Object.new
    y = @method.call { x }
    y.should eql x
    # this would be ideal, but it can't be done in Ruby.  result
    # objects that have a redefined #eql? should do fine.  
    #x.should eql y
  end

  it "should be equal? for results" do
    x = Object.new
    y = @method.call { x }
    y.should equal x
    # this would be ideal, but it can't be done in Ruby.
    #x.should equal y
  end

  it "should be thread safe" do
    x = @method.call { res = 1; 3.times { res = res * 5 ; sleep 1 } ; res}
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
