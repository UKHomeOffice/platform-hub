import angular from 'angular';

import {HubSetupComponent} from './hub-setup.component';
import {ServicesOnboardingComponent} from './services-onboarding.component';

// Main section component name
export const HubSetup = 'hubSetup';
export const ServicesOnboarding = 'servicesOnboarding';

export const OnboardingModule = angular
  .module('app.onboarding', [])
  .component(HubSetup, HubSetupComponent)
  .component(ServicesOnboarding, ServicesOnboardingComponent)
  .name;
