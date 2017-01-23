import angular from 'angular';

import {gitHubIdentityService} from './git_hub_identity.service';
import {IdentitiesManagerComponent} from './identities-manager.component';

// Main section component name
export const IdentitiesManager = 'identitiesManager';

export const IdentitiesModule = angular
  .module('app.identities', [])
  .service('gitHubIdentityService', gitHubIdentityService)
  .component(IdentitiesManager, IdentitiesManagerComponent)
  .name;
