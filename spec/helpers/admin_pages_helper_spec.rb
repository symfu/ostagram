require 'rails_helper'

RSpec.describe AdminPagesHelper, type: :helper do
  describe 'module' do
    it 'is defined' do
      expect(defined?(AdminPagesHelper)).to be_truthy
    end

    it 'is a module' do
      expect(AdminPagesHelper).to be_a(Module)
    end

    it 'has no instance methods' do
      expect(AdminPagesHelper.instance_methods).to be_empty
    end

    it 'has no class methods' do
      expect(AdminPagesHelper.methods - Object.methods).to be_empty
    end

    it 'has no constants' do
      expect(AdminPagesHelper.constants).to be_empty
    end
  end

  describe 'helper inclusion' do
    it 'can be included in a class' do
      test_class = Class.new do
        include AdminPagesHelper
      end
      
      expect(test_class.included_modules).to include(AdminPagesHelper)
    end

    it 'can be extended in a class' do
      test_class = Class.new do
        extend AdminPagesHelper
      end
      
      expect(test_class.singleton_class.included_modules).to include(AdminPagesHelper)
    end
  end

  describe 'future extensibility' do
    it 'is ready for future helper methods' do
      expect(AdminPagesHelper).to be_a(Module)
    end

    it 'can have methods added dynamically' do
      AdminPagesHelper.module_eval do
        def test_method
          'test'
        end
      end
      
      expect(AdminPagesHelper.instance_methods).to include(:test_method)
      
      AdminPagesHelper.module_eval do
        remove_method :test_method
      end
    end
  end
end
