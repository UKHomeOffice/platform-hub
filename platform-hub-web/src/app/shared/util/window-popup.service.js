export const windowPopupService = function ($q, $window, $interval, _) {
  'ngInject';

  const popupHeight = 500;
  const popupWidth = 500;

  const service = {};

  service.open = open;

  return service;

  function open(url, name, options, closeEndpoint) {
    const d = $q.defer();

    const mergedOptions = _.extend(
      defaultWindowPopupOptions(),
      options || {}
    );

    const win = $window.open(url, name, stringifyOptions(mergedOptions));

    const closePredicateFn = generateClosePredicateFn(closeEndpoint);

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

  function defaultWindowPopupOptions() {
    return {
      width: popupHeight,
      height: popupWidth,
      top: $window.screenY + (($window.outerHeight - popupHeight) / 2.5),
      left: $window.screenX + (($window.outerWidth - popupWidth) / 2)
    };
  }

  function generateClosePredicateFn(endpoint) {
    return function (win) {
      return win.location.href === endpoint;
    };
  }
};
