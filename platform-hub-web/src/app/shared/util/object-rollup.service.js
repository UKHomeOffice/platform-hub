export const objectRollupService = function (_) {
  'ngInject';

  const service = {};

  service.rollup = rollup;

  return service;

  function rollup(obj, into) {
    return _rollup(_.cloneDeep(obj), _.cloneDeep(into));
  }

  function _rollup(obj, into) {
    return _.mergeWith(into, obj, (objValue, srcValue) => {
      const [v1, v2] = reconcile(objValue, srcValue);

      if (_.isPlainObject(v1)) {
        return _rollup(v2, v1);
      } else if (_.isArray(v1)) {
        return v1.concat(v2);
      } else if (_.isString(v1)) {
        return v2;
      }
      return v1 + v2;
    });
  }

  function reconcile(objValue, srcValue) {
    if (
      (_.isUndefined(objValue) || _.isNull(objValue)) &&
      (!_.isUndefined(srcValue) || !_.isNull(srcValue))
    ) {
      return [defaultValue(srcValue), srcValue];
    } else if (
      (!_.isUndefined(objValue) || !_.isNull(objValue)) &&
      (_.isUndefined(srcValue) || _.isNull(srcValue))
    ) {
      return [objValue, defaultValue(objValue)];
    }
    return [objValue, srcValue];
  }

  function defaultValue(source) {
    if (_.isPlainObject(source)) {
      return {};
    } else if (_.isArray(source)) {
      return [];
    } else if (_.isString(source)) {
      return '';
    } else if (_.isInteger(source)) {
      return 0;
    } else if (_.isNumber(source)) {
      return 0.0;
    }
    return null;
  }
};
