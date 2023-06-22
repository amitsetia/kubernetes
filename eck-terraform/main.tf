###Install Operator#####

resource "helm_release" "eck_operator" {
  name = "eck-operator"
  repository = "https://helm.elastic.co"
  chart = "eck-operator"
  namespace = "elastic-system"
  create_namespace = true
  force_update = true
  dependency_update = true
}

resource "helm_release" "kube-state-metric" {
  name = "kube-state-metrics"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart = "kube-state-metrics"
  namespace = "kube-system"
  create_namespace = false
 
  set {
    name  = "appVersion"
    value = "2.7.0"
  }
}

resource "kubernetes_namespace" "efk_ns" {
  metadata {
    annotations = {
      name = "monitoring"
    }
    name = "monitoring"
  }
}

data "kubectl_filename_list" "manifests_deployment_op" {
    pattern = "./yamls/*.yaml"
}

resource "kubectl_manifest" "operator_deploy" {
    count = length(data.kubectl_filename_list.manifests_deployment_op.matches)
    yaml_body = file(element(data.kubectl_filename_list.manifests_deployment_op.matches, count.index))
    override_namespace = "monitoring"
    depends_on = [ helm_release.eck_operator ]
}
