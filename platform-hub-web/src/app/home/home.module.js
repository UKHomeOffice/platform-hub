import angular from 'angular';

import {HelpModule} from '../help/help.module';

import {HomeComponent} from './home.component';
import {HomePreloadComponent} from './home-preload.component';

// Main section component names
export const AppHome = 'appHome';
export const HomePreload = 'homePreload';

export const HomeModule = angular
  .module('app.home', [
    HelpModule
  ])
  .component(AppHome, HomeComponent)
  .component(HomePreload, HomePreloadComponent)
  .name;
