import angular from 'angular';

import {apiHelpers} from './api-helpers.factory';
import {apiPagination} from './api-pagination.factory';
import {apiRequestBuilders} from './api-request-builders.factory';
import {hubApiService} from './hub-api.service';

export const HubApiModule = angular
  .module('app.shared.hubApi', [])
  .factory('apiHelpers', apiHelpers)
  .factory('apiPagination', apiPagination)
  .factory('apiRequestBuilders', apiRequestBuilders)
  .service('hubApiService', hubApiService)
  .name;
