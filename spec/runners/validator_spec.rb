# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Onboard::Runners::Validator do
  subject { Object.new.extend(described_class) }

  describe '#validate_askid' do
    it 'accepts valid lowercase-alphanumeric-hyphen askid' do
      result = subject.validate_askid(askid: 'my-app-123')
      expect(result[:valid]).to be true
    end

    it 'rejects askid with uppercase' do
      result = subject.validate_askid(askid: 'MyApp')
      expect(result[:valid]).to be false
      expect(result[:reason]).to include('format')
    end

    it 'rejects empty askid' do
      result = subject.validate_askid(askid: '')
      expect(result[:valid]).to be false
    end

    it 'rejects askid over 63 characters' do
      result = subject.validate_askid(askid: 'a' * 64)
      expect(result[:valid]).to be false
    end
  end

  describe '#check_conflicts' do
    context 'when no systems are available' do
      it 'returns no conflicts' do
        result = subject.check_conflicts(askid: 'new-app')
        expect(result[:conflicts]).to be_empty
      end
    end
  end
end
