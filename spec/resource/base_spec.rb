require 'spec_helper'
describe Served::Resource::Base do
  let(:test_host) { 'http://testhost:3000' }

  describe 'class methods' do
    before :all do
      Served.configure do |config|
        config.hosts = {
          'some_module' => 'http://testhost:3000'
        }
      end
    end

    after :each do
      Served.send(:remove_const, :SomeModule)
    end

    subject {

      module Served
        module SomeModule
          # Test class
          class ResourceTest < Served::Resource::Base
            attribute :test
            attribute :test_with_default, default: 'test'
          end
        end
      end
      Served::SomeModule::ResourceTest
    }

    describe '::attribute' do

      it 'adds the attribute to the attribute list and creates an attr_accessor' do
        expect(subject.attributes.include?(:test)).to be true
        expect(subject.new).to respond_to(:test)
        expect(subject.new).to respond_to(:test=)
      end

      it 'sets the default value if the default option is present' do
        expect(subject.new.test_with_default).to eq('test')
      end

    end

    describe '::resource_name' do

      it 'returns the tableized name of the class' do
        expect(subject.resource_name).to eq 'resource_tests'
      end

    end

    describe '::host' do

      it 'returns the url for SomeModule host' do
        expect(subject.host).to eq test_host
      end

    end

    describe '::connection' do

      it 'creates a new connection instance' do
        expect(subject.client).to be_a(Served::HTTPClient)
      end

    end

    describe '::find' do

      let(:instance) { double(subject) }

      it 'creates a new instance of itself with the provided id and calls reload' do
        expect(subject).to receive(:new).with(id: 1).and_return(instance)
        expect(instance).to receive(:reload).and_return(true)
        subject.find(1)
      end

    end

  end

  describe 'instance methods' do

    before :all do
      Served.configure do |config|
        config.hosts = {
          'some_module' => 'http://testhost:3000'
        }
      end
    end

    after :each do
      Served.send(:remove_const, :SomeModule)
    end

    let(:klass) {
      module Served
        module SomeModule
          # Test class
          class ResourceTest < Served::Resource::Base
            attribute :attr1
            attribute :attr2
            attribute :attr3
          end
        end
      end
      Served::SomeModule::ResourceTest
    }

    describe '#initialize' do

      it 'should initialize and set the attributes passed to #new' do
        subject = klass.new(attr1: 1, attr2: 2)
        expect(subject.attr1).to eq 1
        expect(subject.attr2).to eq 2
      end

    end

    describe '#to_json' do
      context 'with presenter' do

        let(:klass) {
          module Served
            module SomeModule
              # Test class
              class ResourceTest < Served::Resource::Base
                attribute :attr1
                attribute :attr2
                attribute :attr3

                def presenter
                  {attr1: 1}
                end
              end
            end
          end
          Served::SomeModule::ResourceTest
        }

        it 'returns the results of the presenter' do
          expect(klass.new(attr1: 1, attr2: 2).to_json).to eq({attr1: 1}.to_json)
        end

      end

      context 'without presenter' do
        let(:klass) {
          module Served
            module SomeModule
              # Test class
              class ResourceTest < Served::Resource::Base
                attribute :attr1
                attribute :attr2
                attribute :attr3
              end
            end
          end
          Served::SomeModule::ResourceTest
        }

        it 'returns there results of the serialized attributes' do
          expect(klass.new(attr1: 1, attr2: 2).to_json)
            .to eq({klass.resource_name.singularize => { id: nil, attr1: 1, attr2: 2, attr3: nil}}.to_json)
        end
      end
    end

    describe '#save' do

      context 'new record' do

        subject { klass.new(attr1: 1) }

        let(:response) { { subject.resource_name.singularize => { attr1: 1 } } }

        it 'calls reload_with_attributes with the result of  post with the  current attributes' do
          expect(subject).to receive(:post)
                               .and_return(response)
          expect(subject).to receive(:reload_with_attributes).with(response[subject.resource_name.singularize])
          expect(subject.save).to eq true
        end

      end

      context 'existing record' do

        subject { klass.new(id: 1, attr1: 1) }

        let(:response) { { klass.resource_name.singularize => { id: 1, attr1: 1 } } }

        it 'calls reload_with_attributes with the result of  post with the  current attributes' do
          expect(subject).to receive(:put).and_return(response)
          expect(subject).to receive(:reload_with_attributes).with(response[klass.resource_name.singularize])
          subject.save
        end

      end

    end

    describe '#get' do

      subject { klass.new(id: 1) }
      let(:response) { double('Response', body: { klass.resource_name.singularize => { id: 1, attr1: 1 } }, code: 200) }

      it 'calls #handle_response with the result of the GET request' do
        expect(subject).to receive(:handle_response).with(response)
        expect(klass.client).to receive(:get).with("/#{klass.resource_name}/#{subject.id}.json", {}).and_return(response)
        subject.send(:get)
      end

    end

    describe '#handle_response' do

      it 'raises an error when code is not in the 200 range' do
        expect { klass.new.send(:handle_response, double('Response', code: 500)) }.
          to raise_error(Served::Resource::Base::ServiceError)
      end

    end
  end
end