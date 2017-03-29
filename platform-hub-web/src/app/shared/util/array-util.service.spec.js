import angular from 'angular';

import 'angular-mocks';

import {UtilModule} from './util.module';

describe('arrayUtilsService', () => {
  let service = null;

  beforeEach(() => {
    const moduleName = `${UtilModule}.arrayUtilsService.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject(arrayUtilsService => {
    service = arrayUtilsService;
  }));

  describe('.splitBySortedIds', () => {
    describe('given an empty source list', () => {
      const source = [];
      const sortedIds = ['a', 'b'];

      it('should return empty lists back', () => {
        const [left, right] = service.splitBySortedIds(source, sortedIds);
        expect(left).toEqual([]);
        expect(right).toEqual([]);
      });
    });

    describe('given a non-empty source list', () => {
      const source = [
        {id: 'b'},
        {id: 'c'},
        {id: 'a'},
        {id: 'e'},
        {id: 'd'}
      ];

      describe('given empty sorted IDs', () => {
        const sortedIds = [];

        it('should not return an empty list on the left and all items on the right', () => {
          const [left, right] = service.splitBySortedIds(source, sortedIds);
          expect(left).toEqual([]);
          expect(right).toEqual(source);
        });
      });

      describe('given some sorted IDs that all exist', () => {
        const sortedIds = ['c', 'd', 'e'];

        it('should split and reorder accordingly', () => {
          const expectedLeft = [
            {id: 'c'},
            {id: 'd'},
            {id: 'e'}
          ];

          const expectedRight = [
            {id: 'b'},
            {id: 'a'}
          ];

          const [left, right] = service.splitBySortedIds(source, sortedIds);
          expect(left).toEqual(expectedLeft);
          expect(right).toEqual(expectedRight);
        });
      });

      describe('given some sorted IDs with some that don\'t exist', () => {
        const sortedIds = ['e', 'bar', 'c', 'foo'];

        it('should split and reorder accordingly', () => {
          const expectedLeft = [
            {id: 'e'},
            {id: 'c'}
          ];

          const expectedRight = [
            {id: 'b'},
            {id: 'a'},
            {id: 'd'}
          ];

          const [left, right] = service.splitBySortedIds(source, sortedIds);
          expect(left).toEqual(expectedLeft);
          expect(right).toEqual(expectedRight);
        });
      });
    });

    describe('the specific example that was failing before', () => {
      const source = [
        {id: 'build'},
        {id: 'deploy'},
        {id: 'develop'},
        {id: 'manage'}
      ];

      const sortedIds = [
        'develop',
        'build',
        'deploy',
        'manage'
      ];

      it('should split and reorder accordingly', () => {
        const expectedLeft = [
          {id: 'develop'},
          {id: 'build'},
          {id: 'deploy'},
          {id: 'manage'}
        ];

        const [left, right] = service.splitBySortedIds(source, sortedIds);
        expect(left).toEqual(expectedLeft);
        expect(right).toEqual([]);
      });
    });
  });
});
