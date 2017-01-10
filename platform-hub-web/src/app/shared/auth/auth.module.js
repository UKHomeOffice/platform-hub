import angular from 'angular';

import {AuthCardComponent} from './auth-card.component';
import {authService} from './auth.service';
import {LoginDialogController} from './login-dialog.controller';
import {loginDialogService} from './login-dialog.service';

export const AuthModule = angular
  .module('app.shared.auth', [
    'angular-jwt',
    'base64',
    'bc.AngularUrlEncode',
    'ngMaterial'
  ])
  .component('authCard', AuthCardComponent)
  .service('authService', authService)
  .controller('LoginDialogController', LoginDialogController)
  .service('loginDialogService', loginDialogService)
  .name;
