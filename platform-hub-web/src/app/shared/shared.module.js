import angular from 'angular';

import {AuthModule} from './auth/auth.module';
import {HubApiModule} from './hub-api/hub-api.module';
import {UtilModule} from './util/util.module';

export const SharedModule = angular
  .module('app.shared', [
    AuthModule,
    HubApiModule,
    UtilModule
  ])
  .name;
