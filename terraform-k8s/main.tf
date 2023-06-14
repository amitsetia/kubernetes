resource "kubectl_manifest" "ns" {
  yaml_body = templatefile("${path.module}/ns.yaml", {ns = var.namespace })
}
