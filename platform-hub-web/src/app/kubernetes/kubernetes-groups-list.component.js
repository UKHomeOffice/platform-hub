export const KubernetesGroupsListComponent = {
  template: require('./kubernetes-groups-list.html'),
  controller: KubernetesGroupsListController
};

function KubernetesGroupsListController(KubernetesGroups, _) {
  'ngInject';

  const ctrl = this;

  ctrl.sortOptions = [
    {title: 'Last created', value: 'created_at:desc'},
    {title: 'Last updated', value: 'updated_at:desc'}
  ];

  ctrl.loading = true;
  ctrl.searchText = '';
  ctrl.filters = [];
  ctrl.sort = '';
  ctrl.groups = [];

  ctrl.fetchGroups = fetchGroups;

  init();

  function init() {
    ctrl.loading = true;

    KubernetesGroups
      .getFilters()
      .then(filters => {
        // Make sure to store a copy as we'll be mutating this object
        ctrl.filters = _.cloneDeep(filters);

        return fetchGroups();
      });
  }

  function fetchGroups(page = 1) {
    ctrl.loading = true;

    ctrl.groups = [];

    const params = {};

    if (ctrl.searchText) {
      params.q = ctrl.searchText;
    }

    ctrl.filters.forEach(f => {
      if (f.selectedValue) {
        params[f.param] = f.selectedValue;
      }
    });

    if (ctrl.sort) {
      params.sort = ctrl.sort;
    }

    return KubernetesGroups
      .list(page, params)
      .then(groups => {
        ctrl.groups = groups;
      })
      .finally(() => {
        ctrl.loading = false;
      });
  }
}
