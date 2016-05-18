require 'spec_helper'
require 'promise'

shared_examples_for "A Promise" do

  it "should raise ArgumentError when create without block" do
    expect { @method.call }.to raise_error(ArgumentError, "Block required")
  end

  it "should be createable" do
    expect {x = @method.call { 3 + 5 }}.to_not raise_error
  end

  it "should not accept a block requiring arguments" do
    expect {x = @method.call { | x | 3 + 5 }}.to raise_error(ArgumentError, 'Cannot store a promise that requires an argument')
  end

  it "should be forceable" do
    x = @method.call { 3 + 5 }
    expect(x.__force__).to eq 8
    expect(x).to eq 8
  end

  it "should work in conditions (at least when forced)" do
    for value in [true, false, nil, 1, "test", [], {}, Object.new]
      result = (value if value)
      x = @method.call { value }
      expect(x.__force__).to eq value
      expect(x).to eq value
      expect((value if x.__force__)).to eq result
      # Unfortunately this can't be done:
      # expect((value if x)).to eq result
      # The promise/future itself is always not nil, so we get this instead:
      expect((value if x)).to eq value
    end
  end

  it "should respond_to? force" do
    x = @method.call { 3 + 5 }
    expect(x).to respond_to(:force)
  end

  it "should respond_to? __force__" do
    x = @method.call { 3 + 5 }
    expect(x).to respond_to(:__force__)
  end

  it "should respond_to? a method on the result" do
    x = @method.call { 3 + 5 }
    expect(x).to respond_to(:+)
  end

  it "should not respond_to? a method not on the result" do
    x = @method.call { 3 + 5 }
    expect(x).to_not respond_to(:asdf)
  end

  it "should evaluate to a value" do
    expect(5 + @method.call { 1 + 2 }).to eq 8
  end

  it "should hold its value" do
    y = 5
    x = @method.call { y = y + 5 }
    expect(x).to eq 10
    expect(x).to eq 10
  end

  it "should only execute once" do
    y = 1
    x = @method.call { (y += 1) && false }
    expect(x).to eq false
    expect(x).to eq false
    expect(y).to eq 2
  end

  it "should raise exceptions raised during execution when accessed" do
    y = Object.new
    y = @method.call { 1 / 0 }
    expect { y.inspect }.to raise_error ZeroDivisionError
    expect { y.inspect }.to raise_error ZeroDivisionError
  end

  it "should only execute once when execptions are raised" do
    y = 1
    x = @method.call { (y += 1) && (1 / 0) }
    expect { x.inspect }.to raise_error ZeroDivisionError
    expect { x.inspect }.to raise_error ZeroDivisionError
    expect(y).to eq 2
  end

  it "should remain the same for an object reference" do
    h = {}
    x = Object.new
    h[:test] = @method.call { x }
    expect(h[:test]).to eq x
  end

  it "should be eql? for results" do
    x = Object.new
    y = @method.call { x }
    expect(y).to eq x
    # this would be ideal, but it can't be done in Ruby.  result
    # objects that have a redefined #eql? should do fine.  
    #x.should eql y
  end

  it "should be equal? for results" do
    x = Object.new
    y = @method.call { x }
    expect(y).to eq x
    # this would be ideal, but it can't be done in Ruby.
    #x.should equal y
  end

  it "should be thread safe" do
    x = @method.call { res = 1; 3.times { res = res * 5 ; sleep 1 } ; res}
    results = Array.new(10)
    changeds = Array.new(10){false}
    threads = Array.new(10) do |i|
      Thread.new do
        changed = false
        res = old_res = 125
        10.times do |i|
          old_res = res
          res = x + 5
          changed ||= res != old_res && i != 0
          sleep 0.3
        end
        results[i] = res
        changeds[i] = changed
      end
    end
    threads.each do |t|
      t.join
    end
    results.each do |result|
      expect(result).to eq 130
    end
    changeds.each do |changed|
      expect(changed).to eq false
    end
    expect(changeds.size).to eq 10
  end

  describe 'compatibility with Marshal' do
    it 'should not respond_to? marshal_dump' do
      x = @method.call { 3 + 5 }
      expect(x).to_not respond_to(:marshal_dump)
    end

    it 'should respond_to? _dump' do
      x = @method.call { 3 + 5 }
      expect(x).to respond_to(:_dump)
    end
  end
end
