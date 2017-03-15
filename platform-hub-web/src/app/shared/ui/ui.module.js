import angular from 'angular';

import {FormFieldComponent} from './form-field.component';
import {LoadingIndicatorComponent} from './loading-indicator.component';

export const UiModule = angular
  .module('app.shared.ui', [])
  .component('formField', FormFieldComponent)
  .component('loadingIndicator', LoadingIndicatorComponent)
  .name;
