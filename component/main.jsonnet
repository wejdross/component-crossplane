local crossplane = import 'lib/crossplane.libsonnet';
local prometheus = import 'lib/prometheus.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.crossplane;

local namespace = 
  if params.monitoring.enabled && std.member(inv.applications, 'prometheus') then
    if params.monitoring.instance != null then
      prometheus.RegisterNamespace(kube.Namespace(params.namespace), params.monitoring.instance)
    else
      prometheus.RegisterNamespace(kube.Namespace(params.namespace))
  else
    kube.Namespace(params.namespace)
;

{
  '00_namespace': namespace,
  [if std.length(params.providers) > 0 then '10_providers']: [
    crossplane.Provider(provider) {
      spec+: params.providers[provider],
    }
    for provider in std.objectFields(params.providers)
  ],
  [if params.monitoring.enabled then '20_monitoring']: import 'monitoring.libsonnet',
}
