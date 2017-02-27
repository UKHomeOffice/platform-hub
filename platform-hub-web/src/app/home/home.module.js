import angular from 'angular';

import {HelpModule} from '../help/help.module';

import {HomeComponent} from './home.component';

// Main section component name
export const AppHome = 'appHome';

export const HomeModule = angular
  .module('app.home', [
    HelpModule
  ])
  .component(AppHome, HomeComponent)
  .name;
