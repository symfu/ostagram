require 'rails_helper'

RSpec.describe QueueImagesHelper, type: :helper do
  describe 'module' do
    it 'is defined' do
      expect(defined?(QueueImagesHelper)).to be_truthy
    end

    it 'is a module' do
      expect(QueueImagesHelper).to be_a(Module)
    end

    it 'has no instance methods' do
      expect(QueueImagesHelper.instance_methods).to be_empty
    end

    it 'has no class methods' do
      expect(QueueImagesHelper.methods - Object.methods).to be_empty
    end

    it 'has no constants' do
      expect(QueueImagesHelper.constants).to be_empty
    end
  end

  describe 'helper inclusion' do
    it 'can be included in a class' do
      test_class = Class.new do
        include QueueImagesHelper
      end
      
      expect(test_class.included_modules).to include(QueueImagesHelper)
    end

    it 'can be extended in a class' do
      test_class = Class.new do
        extend QueueImagesHelper
      end
      
      expect(test_class.singleton_class.included_modules).to include(QueueImagesHelper)
    end
  end
end
