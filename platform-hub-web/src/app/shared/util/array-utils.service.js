export const arrayUtilsService = function (_) {
  'ngInject';

  const service = {};

  service.splitBySortedIds = splitBySortedIds;

  return service;

  function splitBySortedIds(source, sortedIds) {
    const left = _.times(sortedIds.length, _.constant(null));
    const right = [];

    source.forEach(i => {
      const ix = _.indexOf(sortedIds, i.id);
      if (ix >= 0) {
        left.splice(ix, 1, i);
      } else {
        right.push(i);
      }
    });

    return [_.compact(left), right];
  }
};
