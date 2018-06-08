import angular from 'angular';

import 'angular-mocks';

import {UtilModule} from './util.module';

describe('objectRollupService', () => {
  let service = null;

  beforeEach(() => {
    const moduleName = `${UtilModule}.objectRollupService.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject(objectRollupService => {
    service = objectRollupService;
  }));

  describe('rollup', () => {
    describe('given two deep objects', () => {
      const obj = {
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
          {g0a: 1},
          {g1a: 2}
        ]
      };

      const into = {
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
          {g1a: 3}
        ]
      };

      const expected = {
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
          {g1a: 3},
          {g0a: 1},
          {g1a: 2}
        ]
      };

      it('should return the expected rolled up object', () => {
        expect(service.rollup(obj, into)).toEqual(expected);
      });
    });
  });
});
