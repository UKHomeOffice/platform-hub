import angular from 'angular';

import {IdentitiesListComponent} from './identities-list.component';

export const IdentitiesModule = angular
  .module('app.shared.identities', [])
  .component('identitiesList', IdentitiesListComponent)
  .name;
