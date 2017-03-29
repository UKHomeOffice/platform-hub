import angular from 'angular';

import 'angular-toastr';

import {arrayUtilsService} from './array-utils.service';
import {logger} from './logger.service';
import {windowPopupService} from './window-popup.service';

import 'angular-toastr/dist/angular-toastr.css';

export const UtilModule = angular
  .module('app.shared.util', [
    'toastr'
  ])
  .service('arrayUtilsService', arrayUtilsService)
  .service('logger', logger)
  .service('windowPopupService', windowPopupService)
  .name;
