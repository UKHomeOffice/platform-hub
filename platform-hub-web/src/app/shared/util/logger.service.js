export const logger = function ($log, toastr) {
  'ngInject';

  const service = {};

  service.success = success;
  service.info = info;
  service.error = error;
  service.warning = warning;
  service.debug = debug;

  return service;

  function success(msg) {
    $log.info(msg);
    toastr.success(msg);
  }

  function info(msg) {
    $log.info(msg);
    toastr.info(msg);
  }

  function error(msg) {
    $log.error(msg);
    toastr.error(msg);
  }

  function warning(msg) {
    $log.warn(msg);
    toastr.warning(msg);
  }

  function debug(msgOrObj) {
    $log.debug(msgOrObj);
  }
};
