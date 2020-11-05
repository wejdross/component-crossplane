local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.crossplane;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('crossplane', params.namespace);

{
  crossplane: app,
}
