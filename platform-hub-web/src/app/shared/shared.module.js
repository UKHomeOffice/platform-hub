import angular from 'angular';

import {AuthModule} from './auth/auth.module';
import {HubApiModule} from './hub-api/hub-api.module';
import {UtilModule} from './util/util.module';

import {events} from './events.factory';
import {homeEndpoint} from './home-endpoint.factory';

export const SharedModule = angular
  .module('app.shared', [
    AuthModule,
    HubApiModule,
    UtilModule
  ])
  .factory('events', events)
  .factory('homeEndpoint', homeEndpoint)
  .name;
