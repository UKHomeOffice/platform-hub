import angular from 'angular';

import {AuthModule} from './auth/auth.module';
import {HubApiModule} from './hub-api/hub-api.module';
import {UiModule} from './ui/ui.module';
import {UtilModule} from './util/util.module';

import {events} from './events.factory';
import {homeEndpoint} from './home-endpoint.factory';
import {roleCheckerService} from './role-checker.service';

export const SharedModule = angular
  .module('app.shared', [
    AuthModule,
    HubApiModule,
    UiModule,
    UtilModule
  ])
  .factory('events', events)
  .factory('homeEndpoint', homeEndpoint)
  .service('roleCheckerService', roleCheckerService)
  .name;
