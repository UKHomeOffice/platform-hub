import angular from 'angular';

import 'angular-material';

import {ShellComponent} from './shell.component';

import './layout.scss';

export const LayoutModule = angular
  .module('app.layout', [
    'ngMaterial'
  ])
  .component('appShell', ShellComponent)
  .name;
