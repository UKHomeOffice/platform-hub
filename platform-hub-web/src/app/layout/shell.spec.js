import angular from 'angular';

import 'angular-mocks';

import {LayoutModule} from './layout.module';

describe('appShell component', () => {
  beforeEach(() => {
    const moduleName = `${LayoutModule}.appShell.spec`;
    angular.module(moduleName, [LayoutModule]);
    angular.mock.module(moduleName);
  });

  it('should render content', angular.mock.inject(($rootScope, $compile) => {
    const element = $compile('<app-shell></app-shell>')($rootScope);
    $rootScope.$digest();
    expect(element).toContainElement('div.app-shell');
  }));
});
