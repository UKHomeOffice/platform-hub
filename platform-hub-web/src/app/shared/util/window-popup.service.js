export const windowPopupService = function ($q, $window, $interval, _) {
  'ngInject';

  const service = {};

  service.open = open;

  return service;

  function open(url, name, options, closePredicateFn) {
    const d = $q.defer();

    const win = $window.open(url, name, stringifyOptions(options));

    // Close the window if required, and when closed resolve the promise
    const watcher = $interval(() => {
      try {
        if (win.window && closePredicateFn && closePredicateFn(win.window)) {
          win.close();
        }
      } catch (e) {
        if (e.name === 'SecurityError') {
          // noop – this is most likely a cross origin frame error
        } else {
          throw e;
        }
      }

      if (win.closed || !win.window) {
        d.resolve();
        $interval.cancel(watcher);
      }
    }, 100, 0, false);

    return d.promise;
  }

  function stringifyOptions(options) {
    return _.reduce(options || {}, (result, value, key) => {
      result.push(`${key}=${value}`);
      return result;
    }, []).join(',');
  }
};
