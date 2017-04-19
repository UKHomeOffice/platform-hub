import angular from 'angular';

import {HubSetupComponent} from './hub-setup.component';

// Main section component name
export const HubSetup = 'hubSetup';

export const OnboardingModule = angular
  .module('app.onboarding', [])
  .component(HubSetup, HubSetupComponent)
  .name;
