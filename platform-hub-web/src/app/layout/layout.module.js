import angular from 'angular';

import {ShellComponent} from './shell.component';

import './layout.scss';

export const LayoutModule = angular
  .module('app.layout', [
    'ngMaterial',
    'ngMaterialSidemenu'
  ])
  .component('appShell', ShellComponent)
  .name;
