import angular from 'angular';

import {AuthModule} from './auth/auth.module';
import {HubApiModule} from './hub-api/hub-api.module';
import {IdentitiesModule} from './identities/identities.module';
import {ModelModule} from './model/model.module';
import {UiModule} from './ui/ui.module';
import {UtilModule} from './util/util.module';

import {events} from './events.factory';
import {homeEndpoint} from './home-endpoint.factory';
import {icons} from './icons.factory';
import {onboardingTrigger} from './onboarding-trigger.factory';
import {roleCheckerService} from './role-checker.service';

export const SharedModule = angular
  .module('app.shared', [
    AuthModule,
    HubApiModule,
    IdentitiesModule,
    ModelModule,
    UiModule,
    UtilModule
  ])
  .factory('events', events)
  .factory('homeEndpoint', homeEndpoint)
  .factory('icons', icons)
  .factory('onboardingTrigger', onboardingTrigger)
  .service('roleCheckerService', roleCheckerService)
  .name;
