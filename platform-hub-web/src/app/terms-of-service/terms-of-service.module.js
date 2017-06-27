import angular from 'angular';

import {TermsOfServiceComponent} from './terms-of-service.component';

// Main section component names
export const TermsOfService = 'termsOfService';

export const TermsOfServiceModule = angular
  .module('app.terms-of-service', [])
  .component(TermsOfService, TermsOfServiceComponent)
  .name;
