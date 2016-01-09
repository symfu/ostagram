require 'rails_helper'

RSpec.describe StaticPagesHelper, type: :helper do
  describe 'module' do
    it 'is defined' do
      expect(defined?(StaticPagesHelper)).to be_truthy
    end

    it 'is a module' do
      expect(StaticPagesHelper).to be_a(Module)
    end

    it 'has no instance methods' do
      expect(StaticPagesHelper.instance_methods).to be_empty
    end

    it 'has no class methods' do
      expect(StaticPagesHelper.methods - Object.methods).to be_empty
    end

    it 'has no constants' do
      expect(StaticPagesHelper.constants).to be_empty
    end
  end

  describe 'helper inclusion' do
    it 'can be included in a class' do
      test_class = Class.new do
        include StaticPagesHelper
      end
      
      expect(test_class.included_modules).to include(StaticPagesHelper)
    end

    it 'can be extended in a class' do
      test_class = Class.new do
        extend StaticPagesHelper
      end
      
      expect(test_class.singleton_class.included_modules).to include(StaticPagesHelper)
    end
  end

  describe 'future extensibility' do
    it 'is ready for future helper methods' do
      expect(StaticPagesHelper).to be_a(Module)
    end

    it 'can have methods added dynamically' do
      StaticPagesHelper.module_eval do
        def test_method
          'test'
        end
      end
      
      expect(StaticPagesHelper.instance_methods).to include(:test_method)
      
      StaticPagesHelper.module_eval do
        remove_method :test_method
      end
    end
  end
end
