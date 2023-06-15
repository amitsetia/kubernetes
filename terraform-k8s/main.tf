#resource "kubectl_manifest" "ns" {
#  yaml_body = templatefile("${path.module}/ns-sa.yaml", {
#  		ns = var.namespace 
#		IAM_ROLE = var.IAM_ROLE_ARN		
#	})
#}

data "kubectl_path_documents" "docs" {
    pattern = "./*.yaml"
    vars = {
        ns = var.namespace
	IAM_ROLE = var.IAM_ROLE_ARN
    }
}

resource "kubectl_manifest" "test" {
    count     = length(data.kubectl_path_documents.docs.documents)
    yaml_body = element(data.kubectl_path_documents.docs.documents, count.index)
}
