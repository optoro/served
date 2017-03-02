require 'spec_helper'
describe Served::Resource::Validatable do
  subject do
    Class.new do
      include Served::Resource::Validatable
      attribute :presence,     presence: true
      attribute :numericality, numericality: true
      attribute :format,       format: /[a-z]+/
      attribute :inclusion,    inclusion: { in: %w{foo bar}}

      def self.name
        "TheClass"
      end

      def initialize(*args)
      end
    end
  end

  describe 'validations' do

    it 'should validate presence' do
      instance = subject.new(presence: 'foo')
      instance.validate
      expect(instance.errors[:presence]).to be_empty
      instance = subject.new
      instance.validate
      expect(instance.errors[:presence]).to_not be_empty
    end

    it 'should validate numericality' do
      instance = subject.new(numericality: '1')
      instance.validate
      expect(instance.errors[:numericality]).to be_empty
      instance = subject.new(numericality: 'a')
      instance.validate
      expect(instance.errors[:numericality]).to_not be_empty
    end

    it 'should validate format' do
      instance = subject.new(format: 'abcd')
      instance.validate
      expect(instance.errors[:format]).to be_empty
      instance = subject.new(format: '1234')
      instance.validate
      expect(instance.errors[:format]).to_not be_empty
    end

    it 'should validate inclusion' do
      instance = subject.new(inclusion: 'foo')
      instance.validate
      expect(instance.errors[:inclusion]).to be_empty
      instance = subject.new(inclusion: 'a')
      instance.validate
      expect(instance.errors[:inclusion]).to_not be_empty
    end

  end
end