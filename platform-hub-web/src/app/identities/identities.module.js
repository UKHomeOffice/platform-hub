import angular from 'angular';

import {IdentitiesManagerComponent} from './identities-manager.component';

// Main section component name
export const IdentitiesManager = 'identitiesManager';

export const IdentitiesModule = angular
  .module('app.identities', [])
  .component(IdentitiesManager, IdentitiesManagerComponent)
  .name;
