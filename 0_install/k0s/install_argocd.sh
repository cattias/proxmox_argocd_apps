kubectl create ns argocd
ARGOCD_LATEST=$(curl -sSL https://api.github.com/repos/argoproj/argo-cd/releases/latest | grep '"tag_name":' | head -1 | awk -F '"' '{print $4}' | tr -d 'v')
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v$ARGOCD_LATEST/manifests/install.yaml

argocd admin initial-password -n argocd

argocd repo add https://github.com/cattias/proxmox_argocd_apps_secret.git --username token --password XXXX
argocd repo add https://github.com/cattias/proxmox_argocd_apps.git 

