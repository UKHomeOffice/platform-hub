import angular from 'angular';

import {HomeComponent} from './home.component';

// Main section component name
export const AppHome = 'appHome';

export const HomeModule = angular
  .module('app.home', [])
  .component(AppHome, HomeComponent)
  .name;
