import angular from 'angular';

import {FormFieldComponent} from './form-field.component';
import {LoadingIndicatorComponent} from './loading-indicator.component';
import {SimpleFormatFilter} from './simple-format.filter';

export const UiModule = angular
  .module('app.shared.ui', [])
  .component('formField', FormFieldComponent)
  .component('loadingIndicator', LoadingIndicatorComponent)
  .filter('simpleFormat', SimpleFormatFilter)
  .name;
