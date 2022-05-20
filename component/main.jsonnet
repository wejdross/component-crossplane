local crossplane = import 'lib/crossplane.libsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();

local params = inv.parameters.crossplane;
local on_openshift4 = inv.parameters.facts.distribution;

local controller_config_name = 'provider-config';
local controller_config = crossplane.ControllerConfig(controller_config_name) {
  spec+: {
    podSecurityContext: {},
    securityContext: {},
  },
};

local controller_config_ref = {
  controllerConfigRef: {
    name: controller_config_name,
  },
};

{
  '00_namespace': kube.Namespace(params.namespace),
  [if std.length(params.providers) > 0 then '10_providers']: [
    crossplane.Provider(provider) {
      spec+: params.providers[provider] +
             if on_openshift4 == 'openshift4' then controller_config_ref else {},
    }
    for provider in std.objectFields(params.providers)
  ],
  [if params.monitoring.enabled then '20_monitoring']: import 'monitoring.libsonnet',
  [if on_openshift4 == 'openshift4' then '30_controller_config']: controller_config,
}
