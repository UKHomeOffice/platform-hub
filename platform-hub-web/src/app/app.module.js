/* eslint angular/window-service: 0 */

import angular from 'angular';

import 'angular-animate';
import 'angular-aria';
import 'angular-base64';
import 'angular-cookies';
import 'angular-ivh-treeview';
import 'angular-jwt';
import 'angular-loading-bar';
import 'angular-material';
import 'angular-material-expansion-panel';
import 'angular-material-sidemenu';
import 'angular-messages';
import 'angular-moment';
import 'angular-sanitize';
import 'angular-sortable-view';
import 'angular-ui-router';
import 'angular-url-encode';
import 'ngclipboard';
import 'ng-material-datetimepicker';

import moment from 'moment';
import lodash from 'lodash';

window.moment = moment;
window.MediumEditor = require('medium-editor/dist/js/medium-editor.js');
import 'angular-medium-editor';

import {AnnouncementsModule} from './announcements/announcements.module';
import {AppSettingsModule} from './app-settings/app-settings.module';
import {ContactListsModule} from './contact-lists/contact-lists.module';
import {CostsReportsModule} from './costs-reports/costs-reports.module';
import {DocsSourcesModule} from './docs-sources/docs-sources.module';
import {FeatureFlagsModule} from './feature-flags/feature-flags.module';
import {HelpModule} from './help/help.module';
import {HomeModule} from './home/home.module';
import {IdentitiesModule} from './identities/identities.module';
import {KubernetesModule} from './kubernetes/kubernetes.module';
import {LayoutModule} from './layout/layout.module';
import {OnboardingModule} from './onboarding/onboarding.module';
import {PlatformThemesModule} from './platform-themes/platform-themes.module';
import {ProjectsModule} from './projects/projects.module';
import {QaEntriesModule} from './qa-entries/qa-entries.module';
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
import 'angular-ivh-treeview/dist/ivh-treeview.css';
import 'angular-ivh-treeview/dist/ivh-treeview-theme-basic.css';
import 'angular-material-expansion-panel/dist/md-expansion-panel.css';
import './app.scss';

const name = 'app';

// Config + routes
angular
  .module(name, [
    AnnouncementsModule,
    AppSettingsModule,
    ContactListsModule,
    CostsReportsModule,
    DocsSourcesModule,
    FeatureFlagsModule,
    HelpModule,
    HomeModule,
    IdentitiesModule,
    KubernetesModule,
    LayoutModule,
    OnboardingModule,
    PlatformThemesModule,
    ProjectsModule,
    QaEntriesModule,
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
    'ivh.treeview',
    'material.components.expansionPanels',
    'ngAnimate',
    'ngAria',
    'ngclipboard',
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
    announcements: 'announcements',
    dockerRepos: 'docker_repos',
    docsSync: 'docs_sync',
    helpSearch: 'help_search',
    kubernetesTokens: 'kubernetes_tokens',
    kubernetesTokensEscalatePrivilege: 'kubernetes_tokens_escalate_privilege',
    kubernetesTokensSync: 'kubernetes_tokens_sync',
    projects: 'projects',
    supportRequests: 'support_requests'
  });

// Run function
angular
  .module(name)
  .run(appRun);
