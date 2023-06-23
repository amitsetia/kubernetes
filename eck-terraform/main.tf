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

#resource "kubernetes_service_account" "filebeat" {
#  metadata {
#    name = "filebeat"
#    namespace = kubernetes_namespace.efk_ns.metadata[0].name 
#  }
#}

data "kubectl_filename_list" "efk-deployment" {
    pattern = "./yamls/*.yaml"
}

resource "kubectl_manifest" "operator_deploy" {
    count = length(data.kubectl_filename_list.efk-deployment.matches)
    yaml_body = file(element(data.kubectl_filename_list.efk-deployment.matches, count.index))
    override_namespace = "monitoring"
    depends_on = [ helm_release.eck_operator ]
}
