import angular from 'angular';

import {SharedModule} from '../shared/shared.module';

import {ShellComponent} from './shell.component';

import './layout.scss';

export const LayoutModule = angular
  .module('app.layout', [
    SharedModule,
    'ngMaterial',
    'ngMaterialSidemenu'
  ])
  .component('appShell', ShellComponent)
  .name;
