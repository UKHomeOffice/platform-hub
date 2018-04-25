require 'rails_helper'

RSpec.describe HashRollup do

  subject { HashRollup }

  describe '.rollup' do

    context 'with compatible deep hashes' do
      let :data do
        {
          a: 'a',
          b: 5,
          c: 0.5,
          d: [1, 2],
          e: {
            ea: 'ea',
            eb: 2,
            ec: 1.2,
            ed: [3],
            ee: {
              eea: 10,
              eeb: {
                eeba: {
                  eebaa: 4,
                  eebab: 'foo'
                },
                eebb: 0.6
              }
            }
          },
          f: 10,
          g: [
            { g0a: 1 },
            { g1a: 2 }
          ]
        }
      end

      let :into do
        {
          a: '10',
          b: 10,
          c: 2.6,
          d: [4],
          e: {
            ea: 'ea',
            eb: 4,
            ec: 2.1,
            ed: ['ed'],
            ee: {
              eea: 2,
              eeb: {
                eeba: {
                  eebaa: 5
                }
              }
            }
          },
          g: [
            { g1a: 3 }
          ]
        }
      end

      let :expected do
        {
          a: 'a',
          b: 15,
          c: 3.1,
          d: [4, 1, 2],
          e: {
            ea: 'ea',
            eb: 6,
            ec: 3.3,
            ed: ['ed', 3],
            ee: {
              eea: 12,
              eeb: {
                eeba: {
                  eebaa: 9,
                  eebab: 'foo'
                },
                eebb: 0.6
              }
            }
          },
          f: 10,
          g: [
            { g1a: 3 },
            { g0a: 1 },
            { g1a: 2 }
          ]
        }
      end

      it 'rolls up two deep hashes into one making sure to aggregate values accordingly' do
        expect(subject.rollup(data, into)).to eq expected
      end
    end

    context 'with incompatible hashes' do
      let :data do
        {
          a: 1,
          b: []
        }
      end

      let :into do
        {
          a: 5,
          b: 'b'
        }
      end

      it 'raises an error for mismatched types' do
        expect {
          subject.rollup(data, into).to raise(
            "Mismatch in types detected! Key = b, current value type = String, new value type = Array"
          )
        }
      end
    end

    context 'with missing values / sub hashes' do
      let :list do
        [
          { b: 2, c: { ca: 3 }, d: { db: 5 } },
          { a: 1, d: { da: {  }, db: 5 } },
          { a: 1, b: 2, c: { }, d: { da: { daa: 4 } } },
          { b: 2, c: { ca: 3 }, d: { da: { daa: 4 }, db: 5 } }
        ]
      end

      let :expected do
        {
          a: 2,
          b: 6,
          c: { ca: 6 },
          d: { da: { daa: 8 }, db: 15 }
        }
      end

      it 'rolls up all the hashes into one making sure to aggregate missing values / sub hashes accordingly' do
        result = list.reduce({}) do |acc, h|
          subject.rollup(h, acc)
        end
        expect(result).to eq expected
      end
    end

  end

end
