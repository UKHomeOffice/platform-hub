export const AllocationsListingComponent = {
  bindings: {
    busy: '=',
    items: '<',
    allocatableNoun: '@',
    afterDelete: '&'
  },
  template: require('./allocations-listing.html'),
  controller: AllocationsListingController
};

function AllocationsListingController($mdDialog, hubApiService, logger) {
  'ngInject';

  const ctrl = this;

  ctrl.deleteAllocation = deleteAllocation;

  function deleteAllocation(allocation, targetEvent) {
    const confirm = $mdDialog.confirm()
      .title('Are you sure?')
      .textContent('This will delete the allocation selected')
      .ariaLabel(`Confirm deletion of allocation for ${ctrl.allocatableNoun}`)
      .targetEvent(targetEvent)
      .ok('Do it')
      .cancel('Cancel');

    $mdDialog
      .show(confirm)
      .then(() => {
        ctrl.busy = true;

        return hubApiService
          .deleteAllocation(allocation.id)
          .then(() => {
            logger.success('Allocation deleted');
            return ctrl.afterDelete();
          })
          .finally(() => {
            ctrl.busy = false;
          });
      });
  }
}
