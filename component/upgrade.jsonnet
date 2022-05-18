local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.crossplane;

local crds = [
    'compositeresourcedefinitions.apiextensions.crossplane.io',
    'providerrevisions.pkg.crossplane.io',
    'configurationrevisions.pkg.crossplane.io',
    'controllerconfigs.pkg.crossplane.io',
    'configurations.pkg.crossplane.io',
    'locks.pkg.crossplane.io',
    'compositions.apiextensions.crossplane.io',
    'providers.pkg.crossplane.io',
];

local upgradeScript = importstr './upgrade/patch.sh';

local name = 'crossplane-crd-upgrade';

local role = kube.ClusterRole(name) {
  rules: [
    {
      apiGroups: [ 'apiextensions.k8s.io' ],
      resources: [ 'customresourcedefinitions' ],
      verbs: [ 'get', 'patch' ],
    },
    {
      apiGroups: [ 'pkg.crossplane.io' ],
      resources: [ 'locks' ],
      verbs: [ 'get', 'patch' ],
    },
  ],
};

local serviceAccount = kube.ServiceAccount(name) {
  metadata+: { namespace: params.namespace },
};

local roleBinding = kube.ClusterRoleBinding(name) {
  subjects_: [ serviceAccount ],
  roleRef_: role,
};

local job = kube.Job(name) {
  metadata+: {
    namespace: params.namespace,
    annotations+: {
      'argocd.argoproj.io/hook': 'PreSync',
      'argocd.argoproj.io/hook-delete-policy': 'HookSucceeded',
    },
  },
  spec+: {
    template+: {
      spec+: {
        serviceAccountName: serviceAccount.metadata.name,
        containers_+: {
          patch_crds: kube.Container(name) {
            image: '%s/%s:%s' % [ params.images.kubectl.registry, params.images.kubectl.image, params.images.kubectl.tag ],
            command: [ 'sh' ],
            args: [ '-eu', '-c', upgradeScript ],
            env: [
              { name: 'CRDS_TO_PATCH', value: std.join(' ', crds) },
              { name: 'HOME', value: '/upgrade' },
            ],
            volumeMounts: [
              { name: 'upgrade', mountPath: '/upgrade' },
            ],
          },
        },
        volumes+: [
          { name: 'upgrade', emptyDir: {} },
        ],
      },
    },
  },
};

{
  '00_upgrade': [
    role,
    serviceAccount,
    roleBinding,
    job,
  ],
}
