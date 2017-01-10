import angular from 'angular';

import 'angular-mocks';

import {HomeModule} from './home.module';

describe('appHome component', () => {
  beforeEach(() => {
    const moduleName = `${HomeModule}.appHome.spec`;
    angular.module(moduleName, [HomeModule]);
    angular.mock.module(moduleName);
  });

  it('should render content', angular.mock.inject(($rootScope, $compile) => {
    const element = $compile('<app-home></app-home>')($rootScope);
    $rootScope.$digest();
    expect(
      element.text().trim()
    ).toEqual('');
  }));
});
