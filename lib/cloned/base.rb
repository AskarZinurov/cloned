require 'cloned/dsl'

module Cloned
  class Base
    attr_reader :copy, :target, :destination, :options
    delegate :strategy, :clearing_attributes, to: :class

    def initialize(target:, destination: nil, **options)
      @target = target
      @destination = destination
      @options = options
    end

    def make
      if skip_transaction?
        make_or_fail!
      else
        ActiveRecord::Base.transaction { make_or_fail! }
      end
      copy
    end

    def valid?
      target.presence
    end

    protected

    def skip_transaction?
      options[:skip_transaction]
    end

    def force?
      options[:force].presence
    end

    def optional_before(clon, target)
      options[:before].call(clon, target) if options.key?(:before)
    end

    def optional_after(clon, target)
      options[:after].call(clon, target) if options.key?(:after)
    end

    class << self
      attr_accessor :strategy

      include Cloned::DSL

      delegate :find_copier, to: :strategy
    end

    private

    def copy_association(target_association:, destination:, **options)
      if target_association.respond_to?(:proxy_association)
        copier = strategy.find_copier(target_association.proxy_association.klass)
        target_association.each do |target_item|
          copier.new(target: target_item, destination: destination, **options.merge(skip_transaction: true)).make
        end
      else
        copier = strategy.find_copier(target_association.class)
        copier.new(target: target_association, destination: destination, **options.merge(skip_transaction: true)).make
      end
    end

    def copy_associations(clon)
      self.class.associations.each do |association_id, options|
        copy_association(
          target_association: target.public_send(association_id),
          destination: DestinationProxy.new(clon, association_id),
          **options
        )
      end
    end

    def before(clon, target)
      optional_before(clon, target)
      declared_before(clon, target) if respond_to?(:declared_before)
    end

    def after(clon, target)
      optional_after(clon, target)
      declared_after(clon, target) if respond_to?(:declared_after)
    end

    def prepare(clon)
      clon.assign_attributes(Hash[clearing_attributes.map { |k| [k, nil] }])
      clon
    end

    def validate!
      raise 'Cloning context not valid!' unless valid?
    end

    def make_or_fail!
      validate!
      return if options.key?(:if) && !options[:if].call(target)
      @copy = make_copy(target: target, destination: destination)
      @copy.save! if force?
    end

    def make_copy(target:, destination:)
      clon = prepare(target.dup)
      before(clon, target)
      destination&.concat(clon)
      copy_associations(clon)
      after(clon, target)
      clon
    end
  end
end
