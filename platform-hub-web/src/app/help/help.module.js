import angular from 'angular';

import {FaqComponent} from './faq.component';
import {HelpCentreComponent} from './help-centre.component';

// Main section component names
export const HelpCentre = 'helpCentre';

export const HelpModule = angular
  .module('app.help', [])
  .component('faq', FaqComponent)
  .component(HelpCentre, HelpCentreComponent)
  .name;
