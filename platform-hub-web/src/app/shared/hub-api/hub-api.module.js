import angular from 'angular';

import {hubApiService} from './hub-api.service';

export const HubApiModule = angular
  .module('app.shared.hubApi', [])
  .service('hubApiService', hubApiService)
  .name;
