import angular from 'angular';

import {UtilModule} from './util/util.module';
import {HubApiModule} from './hub-api/hub-api.module';

export const SharedModule = angular
  .module('app.shared', [
    HubApiModule,
    UtilModule
  ])
  .name;
