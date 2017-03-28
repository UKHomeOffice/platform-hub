import angular from 'angular';

import 'angular-mocks';

import {HomeModule} from './home.module';

describe('appHome component', () => {
  let $httpBackend;

  beforeEach(() => {
    const moduleName = `${HomeModule}.appHome.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject(_$httpBackend_ => {
    $httpBackend = _$httpBackend_;

    $httpBackend
      .whenGET(/.+/)
      .respond('{}');
  }));

  it('should render content', angular.mock.inject(($rootScope, $compile) => {
    const element = $compile('<app-home></app-home>')($rootScope);
    $rootScope.$digest();
    expect(element).toContainElement('div.app-home');
  }));
});
