variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

variable "gitops_repository_url" {
  type        = string
  default     = "https://github.com/mcarval4/todolist-gitops.git"
  description = "Git repository reconciled by Argo CD."
}
