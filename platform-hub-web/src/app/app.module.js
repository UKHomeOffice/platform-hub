/* eslint angular/window-service: 0 */

import angular from 'angular';

import 'angular-ui-router';
import 'angular-animate';
import 'angular-aria';
import 'angular-loading-bar';
import 'angular-material';
import 'angular-messages';
import 'angular-sanitize';

import moment from 'moment';
import lodash from 'lodash';

import {HomeModule} from './home/home.module';
import {LayoutModule} from './layout/layout.module';
import {SharedModule} from './shared/shared.module';

import {appConfig} from './app.config';
import {appRoutes} from './app.routes';
import {appRun} from './app.run';

import 'angular-material/angular-material.css';  // Make sure this is available across the app
import './app.scss';

const name = 'app';

angular
  .module(name, [
    HomeModule,
    LayoutModule,
    SharedModule,
    'angular-loading-bar',
    'ngAnimate',
    'ngAria',
    'ngMaterial',
    'ngMessages',
    'ngSanitize',
    'ui.router'
  ])
  .config(appConfig)
  .config(appRoutes)
  .run(appRun);

// Top level dependencies as injectable AngularJS constants
angular
  .module(name)
  .constant('moment', moment)
  .constant('_', lodash);

// App specific constants
const apiEndpoint = `${window.location.protocol}//${window.location.hostname}:8080`;
angular
  .module(name)
  .constant('apiEndpoint', apiEndpoint);
