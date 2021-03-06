require 'spec_helper'
describe Served::Resource::Configurable do
  subject do
    Class.new do
      include Served::Resource::Configurable
    end
  end

  it 'allows a value to be configurable' do
    subject.send(:class_configurable, :foo)
    subject.foo 'bar'
    expect(subject.foo).to eq 'bar'
  end

  it 'return s a default value' do
    subject.send(:class_configurable, :foo, default: 'baz')
    expect(subject.foo).to eq 'baz'
  end

  it 'overrides the default value' do
    subject.send(:class_configurable, :foo, default: 'baz')
    subject.foo 'bar'
    expect(subject.foo).to eq 'bar'
  end

  it 'calls a proc if it is passed as default' do
    subject.send(:class_configurable, :foo, default: proc { 'baz' })
    subject.foo
    expect(subject.foo).to eq 'baz'
  end

  it 'calls the block if passed' do
    subject.send(:class_configurable, :foo, proc { 'baz' })
    expect(subject.foo).to eq 'baz'
  end

  it 'defines an accessible instance method' do
    subject.send(:class_configurable, :foo, proc { 'baz' })
    expect(subject.new.foo).to eq 'baz'
  end

  context 'subclass' do
    let!(:parent) do
      Class.new do
        include Served::Resource::Configurable
        class_configurable :foo, default: 'bar'
        class_configurable :fixnum do
          5
        end
      end
    end

    subject do
      Class.new(parent)
    end

    it 'should not blow up on a fixnum' do
      expect { subject.fixnum }.to_not raise_exception
    end

    it "should inherit the parent's default" do
      expect(subject.foo).to eq 'bar'
    end

    it 'should allow setting of own attribute without changing the parent' do
      subject.foo 'baz'
      expect(subject.foo).to eq 'baz'
      expect(parent.foo).to eq 'bar'
    end
  end
end
