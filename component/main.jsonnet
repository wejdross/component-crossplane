local crossplane = import 'lib/crossplane.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.crossplane;

{
  '00_namespace': kube.Namespace(params.namespace),
  [if std.length(params.providers) > 0 then '10_providers']: [
    crossplane.Provider(provider) {
      spec+: params.providers[provider],
    }
    for provider in std.objectFields(params.providers)
  ],
}
