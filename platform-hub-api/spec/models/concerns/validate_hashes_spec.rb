require 'rails_helper'

describe 'ValidateHashes Concern', type: :model do

  module ValidateHashesSpecHelper
    SCHEMA_ONE = {
      'a' => String,
      'b' => [ :optional, TrueClass ],
      'c' => { 'cc' => [[String]] },
      'd' => { 'dd' => { 'ddd' => [[{ 'id' => Integer }]] } },
      'e' => [ :optional, NilClass, [[String]] ]
    }

    SCHEMA_TWO = {
      'foo' => String,
      'bar' => { 'baz' => [:optional, TrueClass] }
    }
  end


  with_model :VHModel do
    table do |t|
      t.json :hash_one
    end

    model do
      include ValidateHashes

      validate_hashes(
        hash_one: {
          schema: ValidateHashesSpecHelper::SCHEMA_ONE,
          unique_checks: [
            { array_path: [ 'c', 'cc' ] },
            { array_path: [ 'd', 'dd', 'ddd' ], obj_key: 'id' },
            { array_path: 'e' }
          ]
        },
        hash_two: {
          schema: ValidateHashesSpecHelper::SCHEMA_TWO
        }
      )

      def hash_two
        { 'foo' => 'Hello', 'bar' => { }, 'baz' => 'Unknown keys are allowed!' }
      end
    end
  end

  before do
    @record = VHModel.new

    expect(@record).to receive(:validate_hashes_validate_field)
      .with(:hash_one, { schema: ValidateHashesSpecHelper::SCHEMA_ONE, unique_checks: anything })
      .and_call_original
    expect(@record).to receive(:validate_hashes_validate_field)
      .with(:hash_two, { schema: ValidateHashesSpecHelper::SCHEMA_TWO })
      .and_call_original
  end


  context 'with an empty model' do
    it 'should be valid' do
      expect(@record).to be_valid
    end
  end

  context 'with a non-empty model' do
    before do
      @record.hash_one = hash_one
    end

    context 'with valid hash_one' do
      let :hash_one do
        {
          'a' => "Oi hai!",
          'c' => { 'cc' => ['hellow', 'orld'] },
          'd' => { 'dd' => { 'ddd' => [ { 'id' => 1 }, { 'id' => 2 } ]}},
          'e' => ['hellow']
        }
      end

      it 'should be valid' do
        expect(@record).to be_valid
      end
    end

    context 'with empty hash for hash_one' do
      let :hash_one do
        { }
      end

      let :expected_errors do
        [
          '- "a" should be present',
          '- "c" should be present',
          '- "d" should be present'
        ]
      end

      it 'should be invalid' do
        expect(@record).to be_invalid
        expect(@record.errors[:hash_one]).to match_array expected_errors
        expect(@record.errors[:hash_two]).to match_array []
      end
    end

    context 'with invalid hash_one - doesn\'t match schema' do
      let :hash_one do
        {
          'a' => 1,
          'b' => 'false',
          'd' => { 'dd' => [1,2,3] }
        }
      end

      let :expected_errors do
        [
          '- "a" should be a/an String',
          '- "b" should be true or false',
          '- "b" should be one of absent (marked as :optional), true or false',
          '- "c" should be present',
          '- "d"["dd"] should be a Hash matching {schema with keys ["ddd"]}'
        ]
      end

      it 'should be invalid' do
        expect(@record).to be_invalid
        expect(@record.errors[:hash_one]).to match_array expected_errors
        expect(@record.errors[:hash_two]).to match_array []
      end
    end

    context 'with invalid hash_one - string array has dups' do
      let :hash_one do
        {
          'a' => "Oi hai!",
          'b' => false,
          'c' => { 'cc' => [ 'hellow', 'hellow' ] },
          'd' => { 'dd' => { 'ddd' => [ { 'id' => 1 }, { 'id' => 2 } ]}},
          'e' => ['hellow', 'hellow']
        }
      end

      let :expected_errors do
        [
          '- c.cc contains duplicate values',
          '- e contains duplicate values'
        ]
      end

      it 'should be invalid' do
        expect(@record).to be_invalid
        expect(@record.errors[:hash_one]).to match_array expected_errors
        expect(@record.errors[:hash_two]).to match_array []
      end
    end

    context 'with invalid hash_one - obj array has dups' do
      let :hash_one do
        {
          'a' => "Oi hai!",
          'b' => false,
          'c' => { 'cc' => [ 'hellow', 'orld' ] },
          'd' => { 'dd' => { 'ddd' => [ { 'id' => 2 }, { 'id' => 2 } ]}},
          'e' => ['hellow']
        }
      end

      let :expected_errors do
        [
          '- d.dd.ddd contains duplicate values for property: id'
        ]
      end

      it 'should be invalid' do
        expect(@record).to be_invalid
        expect(@record.errors[:hash_one]).to match_array expected_errors
        expect(@record.errors[:hash_two]).to match_array []
      end
    end

    context 'with invalid hash_one - dups + array is nil when it shouldn\'t be' do
      let :hash_one do
        {
          'a' => "Oi hai!",
          'b' => false,
          'c' => { 'cc' => [ 'hellow', 'orld' ] },
          'd' => { 'dd' => { 'ddd' => [ { 'id' => 2 }, { 'id' => 2 } ]}},
          'e' => nil
        }
      end

      let :expected_errors do
        [
          '- d.dd.ddd contains duplicate values for property: id',
          '- e is nil when it shouldn\'t be'
        ]
      end

      it 'should be invalid' do
        expect(@record).to be_invalid
        expect(@record.errors[:hash_one]).to match_array expected_errors
        expect(@record.errors[:hash_two]).to match_array []
      end
    end
  end

end
