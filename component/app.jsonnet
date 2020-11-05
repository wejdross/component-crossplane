local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.crossplane;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('crossplane', params.namespace) {
  spec+: {
    ignoreDifferences: [{
      group: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: name,
      jsonPointers: ['/rules'],
    } for name in ['crossplane']],
  },
};

{
  crossplane: app,
}
