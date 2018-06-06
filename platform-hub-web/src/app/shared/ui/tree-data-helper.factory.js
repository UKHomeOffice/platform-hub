export const treeDataHelper = function (logger, _) {
  'ngInject';

  return {
    objectToTreeData
  };

  function objectToTreeData(obj, valueFormatter) {
    if (!valueFormatter) {
      valueFormatter = _.identity;
    }

    if (!_.isPlainObject(obj)) {
      logger.debug(`WARNING: treeViewHelper.objectToTreeData was called with a non-object: ${obj}`);
    }

    return _.map(obj, (value, key) => processEntry(value, key, valueFormatter));
  }

  function processEntry(value, key, valueFormatter) {
    if (_.isPlainObject(value)) {
      return {
        label: key || '<object>',
        children: objectToTreeData(value, valueFormatter)
      };
    } else if (_.isArray(value)) {
      const lengthString = `(${value.length} ${value.length === 1 ? 'item' : 'items'})`;
      const label = key ? `${key} ${lengthString}` : `<array> ${lengthString}`;
      return {
        label,
        children: value.map(v => processEntry(v, null, valueFormatter))
      };
    }

    // Assuming we have a primitive type at this point
    const formattedValue = valueFormatter(value);
    return {
      label: key ? `${key}: ${formattedValue}` : formattedValue
    };
  }
};
