require_relative 'response_invalid'
require_relative 'invalid_attribute_serializer'

module Served
  module Resource
    module Serializable
      extend ActiveSupport::Concern

      # pseudo boolean class for serialization
      unless Object.const_defined?(:Boolean)
        class ::Boolean
        end
      end

      included do
        include Configurable
        include Attributable

        class_configurable :serializer, default: Served.config.serializer
        class_configurable :use_root_node, default: Served.config.use_root_node
      end

      module ClassMethods
        def load(string)
          begin
            result = serializer.load(self, string)
          rescue StandardError => e
            raise ResponseInvalid.new(self, e)
          end
          raise ResponseInvalid.new(self) unless result
          result
        end

        def from_hash(hash)
          hash = hash.clone
          hash.each do |name, value|
            hash[name] = serialize_attribute(name, value)
          end
          hash.symbolize_keys
        end

        private

        def attribute_serializer_for(type)
          # case statement wont work here because of how it does class matching
          return ->(v) { return v }              unless type # nil
          return ->(v) { return v.try(:to_i)   } if type == Integer || type == Fixnum
          return ->(v) { return v.try(:to_s)   } if type == String
          return ->(v) { return v.try(:to_sym) } if type == Symbol
          return ->(v) { return v.try(:to_f)   } if type == Float
          return ->(v) { return v.try(:to_a)   } if type == Array
          if type == Boolean
            return lambda do |v|
              return false unless v == "true" || v.is_a?(TrueClass)
              true
            end
          end

          if type.ancestors.include?(Served::Resource::Base) ||
              type.ancestors.include?(Served::Attribute::Base)
            return ->(v) { type.new(v) }
          end

          raise InvalidAttributeSerializer.new(type)
        end

        def serialize_attribute(attr, value)
          return false unless attributes[attr.to_sym]
          serializer = attribute_serializer_for(attributes[attr.to_sym][:serialize])
          if value.is_a? Array
            # TODO: Remove the Array class check below in 1.0, only here
            # for backwards compatibility
            return value if attributes[attr.to_sym][:serialize].nil? ||
              attributes[attr.to_sym][:serialize] == Array

            value.collect do |v|
              if v.is_a? attributes[attr.to_sym][:serialize]
                v
              else
                serializer.call(v)
              end
            end
          else
            serializer.call(value)
          end
        end
      end

      def to_json(*_args)
        dump
      end

      def dump
        if respond_to?(:presenter)
          warn 'DEPRECATION WARNING: using presenters is deprecated and will be removed in served 1.0'
          return presenter.to_json
        end
        self.class.serializer.dump(self, attributes)
      end

      def load(string)
        self.class.serializer.load(string)
      end
    end
  end
end
