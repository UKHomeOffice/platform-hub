import angular from 'angular';

import 'angular-toastr';

import {logger} from './logger.service';

export const UtilModule = angular
  .module('app.shared.util', [
    'toastr'
  ])
  .service('logger', logger)
  .name;
