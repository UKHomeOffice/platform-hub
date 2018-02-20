import angular from 'angular';

import 'angular-mocks';

import {UiModule} from './ui.module';

describe('treeDataHelper', () => {
  let helper = null;

  beforeEach(() => {
    const moduleName = `${UiModule}.treeDataHelper.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject(treeDataHelper => {
    helper = treeDataHelper;
  }));

  describe('objectToTreeData', () => {
    describe('given an empty object', () => {
      it('should return an empty array', () => {
        expect(helper.objectToTreeData({})).toEqual([]);
      });
    });

    describe('given a non-empty simple object', () => {
      const obj = {
        a: 'A',
        b: 'B'
      };

      const expected = [
        {label: 'a: A'},
        {label: 'b: B'}
      ];

      it('should return the expected array of tree data nodes', () => {
        expect(helper.objectToTreeData(obj)).toEqual(expected);
      });
    });

    describe('given a non-empty object with embedded objects and arrays', () => {
      const obj = {
        a: {
          ab: 'AB',
          ac: [
            'ACA',
            {
              acb: 'ACB',
              acc: 'ACC'
            }
          ]
        },
        b: 'B',
        c: [
          {
            ca: 'CA',
            cb: 'CB'
          },
          {
            cc: ['cca']
          },
          'CD'
        ],
        d: [
          [
            'da',
            {
              db: 'DB'
            }
          ]
        ]
      };

      const expected = [
        {
          label: 'a',
          children: [
            {label: 'ab: AB'},
            {
              label: 'ac (2 items)',
              children: [
                {label: 'ACA'},
                {
                  label: '<object>',
                  children: [
                    {label: 'acb: ACB'},
                    {label: 'acc: ACC'}
                  ]
                }
              ]
            }
          ]
        },
        {label: 'b: B'},
        {
          label: 'c (3 items)',
          children: [
            {
              label: '<object>',
              children: [
                {label: 'ca: CA'},
                {label: 'cb: CB'}
              ]
            },
            {
              label: '<object>',
              children: [
                {
                  label: 'cc (1 item)',
                  children: [
                    {label: 'cca'}
                  ]
                }
              ]
            },
            {label: 'CD'}
          ]
        },
        {
          label: 'd (1 item)',
          children: [
            {
              label: '<array> (2 items)',
              children: [
                {label: 'da'},
                {
                  label: '<object>',
                  children: [
                    {label: 'db: DB'}
                  ]
                }
              ]
            }
          ]
        }
      ];

      it('should return the expected array of tree data nodes', () => {
        expect(helper.objectToTreeData(obj)).toEqual(expected);
      });
    });
  });
});
