import angular from 'angular';

import 'angular-mocks';

import {LayoutModule} from './layout.module';

describe('appShell component', () => {
  let $httpBackend;

  beforeEach(() => {
    const moduleName = `${LayoutModule}.appShell.spec`;
    angular.module(moduleName, ['app']);
    angular.mock.module(moduleName);
  });

  beforeEach(angular.mock.inject(_$httpBackend_ => {
    $httpBackend = _$httpBackend_;

    $httpBackend
      .whenGET(/.+/)
      .respond("{}");
  }));

  it('should render content', angular.mock.inject(($rootScope, $compile) => {
    const element = $compile('<app-shell></app-shell>')($rootScope);
    $rootScope.$digest();
    expect(element).toContainElement('div.app-shell');
  }));
});
