export const objectRollupService = function (_) {
  'ngInject';

  const service = {};

  service.rollup = rollup;

  return service;

  function rollup(obj, into) {
    return _.mergeWith(obj, into, (objValue, srcValue) => {
      if (_.isObject(objValue)) {
        return rollup(srcValue, objValue);
      } else if (_.isArray(objValue)) {
        return objValue.concat(srcValue);
      } else if (_.isString(objValue)) {
        return objValue;
      }
      return objValue + srcValue;
    });
  }
};
