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
      expect(Promise.ancestors).to include BasicObject
    end
  end

  it_should_behave_like "A Promise"

  it "should delay execution" do
    value = 5
    x = @method.call { value = 10 ; value }
    expect(value).to eq 5
    y = x + 5
    expect(y).to eq 15
    expect(value).to eq 10
  end

  it "should delay execution of invalid code" do
    expect {x = [ 1, x / 0 ]}.to raise_error
    expect {x = [ 1, @method.call { x / 0 }]}.to_not raise_error
  end

  describe 'an object referencing a promise' do
    class ClassResulting
      attr_reader :value
      def initialize(value)
        @value = value
      end
      def marshal_dump
        [@value]
      end
      def marshal_load(custom_struct)
        @value = custom_struct[0]
      end
    end

    class ClassReferencingAPromise
      attr_reader :long_computation
      def initialize
        @long_computation = promise { ClassResulting.new(8) }
      end
    end
    
    it 'can be marshaled and unmarshalled' do
      clazz_ = Marshal.load(Marshal.dump(ClassReferencingAPromise.new))
      expect(clazz_.long_computation.value).to eq 8
    end

    it "should finished when timeout" do
      # timeout
      x = promise(timeout:1){ sleep 2; 5 }
      expect{x + 5}.to raise_error(::Timeout::Error)
  
      # not timeout
      x = promise(timeout:2){ sleep 1; 5 }
      expect(x + 5).to eq 10
    end
  end
end
