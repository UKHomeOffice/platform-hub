import angular from 'angular';

import {LoadingIndicatorComponent} from './loading-indicator.component';

export const UiModule = angular
  .module('app.shared.ui', [])
  .component('loadingIndicator', LoadingIndicatorComponent)
  .name;
