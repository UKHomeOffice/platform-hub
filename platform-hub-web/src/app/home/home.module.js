import angular from 'angular';

import {HomeComponent} from './home.component';

// Define the app section name
export const AppHome = 'appHome';

export const HomeModule = angular
  .module('app.home', [])
  .component(AppHome, HomeComponent)
  .name;
