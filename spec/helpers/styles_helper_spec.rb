require 'rails_helper'

RSpec.describe StylesHelper, type: :helper do
  describe 'module' do
    it 'is defined' do
      expect(defined?(StylesHelper)).to be_truthy
    end

    it 'is a module' do
      expect(StylesHelper).to be_a(Module)
    end

    it 'has no instance methods' do
      expect(StylesHelper.instance_methods).to be_empty
    end

    it 'has no class methods' do
      expect(StylesHelper.methods - Object.methods).to be_empty
    end

    it 'has no constants' do
      expect(StylesHelper.constants).to be_empty
    end
  end

  describe 'helper inclusion' do
    it 'can be included in a class' do
      test_class = Class.new do
        include StylesHelper
      end
      
      expect(test_class.included_modules).to include(StylesHelper)
    end

    it 'can be extended in a class' do
      test_class = Class.new do
        extend StylesHelper
      end
      
      expect(test_class.singleton_class.included_modules).to include(StylesHelper)
    end
  end
end
