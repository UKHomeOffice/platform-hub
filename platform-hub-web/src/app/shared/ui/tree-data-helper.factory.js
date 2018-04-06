export const treeDataHelper = function (logger, _) {
  'ngInject';

  return {
    objectToTreeData
  };

  function objectToTreeData(obj) {
    if (!_.isPlainObject(obj)) {
      logger.debug(`WARNING: treeViewHelper.objectToTreeData was called with a non-object: ${obj}`);
    }

    return _.map(obj, processEntry);
  }

  function processEntry(value, key) {
    if (_.isPlainObject(value)) {
      return {
        label: key || '<object>',
        children: objectToTreeData(value)
      };
    } else if (_.isArray(value)) {
      const lengthString = `(${value.length} ${value.length === 1 ? 'item' : 'items'})`;
      const label = key ? `${key} ${lengthString}` : `<array> ${lengthString}`;
      return {
        label,
        children: value.map(v => processEntry(v))
      };
    }

    // Assuming we have a primitive type at this point
    return {
      label: key ? `${key}: ${value}` : value
    };
  }
};
