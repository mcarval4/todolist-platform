resource "helm_release" "cilium" {
  name             = "cilium"
  namespace        = "kube-system"
  repository       = "https://helm.cilium.io/"
  chart            = "cilium"
  version          = "1.16.5"
  create_namespace = false
  wait             = true
  timeout          = 600
  values           = [file("${path.module}/values/cilium.yaml")]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.12"
  create_namespace = true
  wait             = true
  timeout          = 600
  values           = [file("${path.module}/values/argocd.yaml")]
  depends_on       = [helm_release.cilium]
}

resource "helm_release" "kyverno" {
  name             = "kyverno"
  namespace        = "kyverno"
  repository       = "https://kyverno.github.io/kyverno/"
  chart            = "kyverno"
  version          = "3.3.6"
  create_namespace = true
  wait             = true
  timeout          = 600
  values           = [file("${path.module}/values/kyverno.yaml")]
  depends_on       = [helm_release.cilium]
}

resource "helm_release" "cnpg" {
  name             = "cloudnative-pg"
  namespace        = "cnpg-system"
  repository       = "https://cloudnative-pg.github.io/charts"
  chart            = "cloudnative-pg"
  version          = "0.22.1"
  create_namespace = true
  wait             = true
  timeout          = 600
  depends_on       = [helm_release.cilium]
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  namespace        = "kube-system"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.12.2"
  create_namespace = false
  wait             = true
  timeout          = 600
  values           = [file("${path.module}/values/metrics-server.yaml")]
  depends_on       = [helm_release.cilium]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus"
  version          = "25.27.0"
  create_namespace = true
  wait             = true
  timeout          = 600
  values           = [file("${path.module}/values/prometheus.yaml")]
  depends_on       = [helm_release.cilium]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  namespace        = "monitoring"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  version          = "8.8.2"
  create_namespace = true
  wait             = true
  timeout          = 600
  values           = [file("${path.module}/values/grafana.yaml")]
  depends_on       = [helm_release.prometheus]
}

resource "local_file" "argocd_application" {
  filename = "${path.module}/todolist-local.generated.yaml"
  content = templatefile("${path.module}/../../../bootstrap/todolist-local.yaml.tftpl", {
    gitops_repository_url = var.gitops_repository_url
  })
}

resource "null_resource" "gitops_bootstrap" {
  triggers = {
    application = local_file.argocd_application.content_sha256
  }

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.argocd_application.filename}"
  }

  depends_on = [helm_release.argocd, helm_release.kyverno, helm_release.cnpg]
}

resource "null_resource" "gitops_bootstrap_cleanup" {
  triggers = {
    application = "todolist"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete application/todolist -n argocd --ignore-not-found"
  }

  depends_on = [null_resource.gitops_bootstrap]
}
