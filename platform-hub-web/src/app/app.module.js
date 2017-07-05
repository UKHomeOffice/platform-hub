/* eslint angular/window-service: 0 */

import angular from 'angular';

import 'angular-animate';
import 'angular-aria';
import 'angular-base64';
import 'angular-cookies';
import 'angular-jwt';
import 'angular-loading-bar';
import 'angular-material';
import 'angular-material-sidemenu';
import 'angular-messages';
import 'angular-moment';
import 'angular-sanitize';
import 'angular-sortable-view';
import 'angular-ui-router';
import 'angular-url-encode';
import 'ng-material-datetimepicker';

import moment from 'moment';
import lodash from 'lodash';

window.moment = moment;
window.MediumEditor = require('medium-editor/dist/js/medium-editor.js');
import 'angular-medium-editor';

import {AnnouncementsModule} from './announcements/announcements.module';
import {AppSettingsModule} from './app-settings/app-settings.module';
import {ContactListsModule} from './contact-lists/contact-lists.module';
import {HelpModule} from './help/help.module';
import {HomeModule} from './home/home.module';
import {IdentitiesModule} from './identities/identities.module';
import {KubernetesTokensModule} from './kubernetes-tokens/kubernetes-tokens.module';
import {LayoutModule} from './layout/layout.module';
import {OnboardingModule} from './onboarding/onboarding.module';
import {PlatformThemesModule} from './platform-themes/platform-themes.module';
import {ProjectsModule} from './projects/projects.module';
import {SharedModule} from './shared/shared.module';
import {TermsOfServiceModule} from './terms-of-service/terms-of-service.module';
import {UsersModule} from './users/users.module';

import {appConfig} from './app.config';
import {appRoutes} from './app.routes';
import {appRun} from './app.run';

import 'normalize.css';
import 'angular-material/angular-material.css';  // Make sure this is available across the app
import 'angular-material-sidemenu/dest/angular-material-sidemenu.css';
import 'medium-editor/dist/css/medium-editor.css';
import 'medium-editor/dist/css/themes/beagle.css';
import 'ng-material-datetimepicker/dist/material-datetimepicker.min.css';
import './app.scss';

const name = 'app';

// Config + routes
angular
  .module(name, [
    AnnouncementsModule,
    AppSettingsModule,
    ContactListsModule,
    HelpModule,
    HomeModule,
    IdentitiesModule,
    KubernetesTokensModule,
    LayoutModule,
    OnboardingModule,
    PlatformThemesModule,
    ProjectsModule,
    SharedModule,
    TermsOfServiceModule,
    UsersModule,
    'angular-jwt',
    'angular-loading-bar',
    'angular-medium-editor',
    'angular-sortable-view',
    'angularMoment',
    'base64',
    'bc.AngularUrlEncode',
    'ngAnimate',
    'ngAria',
    'ngCookies',
    'ngMaterial',
    'ngMaterialDatePicker',
    'ngMaterialSidemenu',
    'ngMessages',
    'ngSanitize',
    'ui.router'
  ])
  .config(appConfig)
  .config(appRoutes);

// Top level dependencies as injectable AngularJS constants
angular
  .module(name)
  .constant('moment', moment)
  .constant('_', lodash);

// App specific constants
const apiEndpoint = '/api';
angular
  .module(name)
  .constant('apiEndpoint', apiEndpoint)
  .constant('apiBackoffTimeMs', 2000)
  .constant('featureFlagKeys', {
    kubernetesTokens: 'kubernetes_tokens'
  });

// Run function
angular
  .module(name)
  .run(appRun);
