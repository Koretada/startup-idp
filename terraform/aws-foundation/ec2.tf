data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "bastion" {
  key_name   = "${local.prefix_name}-admin-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_instance" "ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_type
  subnet_id                   = aws_subnet.public.id
  security_groups             = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.k3s_instance_profile.id
  associate_public_ip_address = true
  user_data_replace_on_change = true
  key_name                    = aws_key_pair.bastion.key_name
  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    # 1. Paquets requis
    apt-get update && apt-get install -y curl bash-completion

    # 2. Recuperation securisee de l'IP publique avec retry
    TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
    PUBLIC_IP=""
    for i in {1..10}; do
      PUBLIC_IP=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 || true)
      [ -n "$PUBLIC_IP" ] && break
      sleep 2
    done

    EXTRA_ARGS=""
    [ -n "$PUBLIC_IP" ] && EXTRA_ARGS="--tls-san $PUBLIC_IP"

    # 3. Installation K3s
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$EXTRA_ARGS --disable traefik --write-kubeconfig-mode 644" sh -

    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    # 4. Configuration Bash et autocompletion
    kubectl completion bash > /etc/bash_completion.d/kubectl

    for BASHRC in /home/ubuntu/.bashrc /root/.bashrc; do
      echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> "$BASHRC"
      echo "source /etc/bash_completion.d/kubectl" >> "$BASHRC"
      echo "alias k=kubectl" >> "$BASHRC"
      echo "complete -o default -F __start_kubectl k" >> "$BASHRC"
    done

    # 5. Attente de disponibilite du node
    until kubectl get nodes | grep -q "Ready"; do
      sleep 5
    done

    # 6. Deploiement ArgoCD
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # 7. Creation du service systemd pour le port-forward
    cat > /etc/systemd/system/argocd-port-forward.service << 'SERVICE'
    [Unit]
    Description=Port-forward automatique pour ArgoCD
    After=k3s.service
    Wants=k3s.service

    [Service]
    Type=simple
    Environment="KUBECONFIG=/etc/rancher/k3s/k3s.yaml"
    ExecStart=/usr/local/bin/kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
    Restart=always
    RestartSec=5
    User=root

    [Install]
    WantedBy=multi-user.target
    SERVICE

    systemctl daemon-reload
    systemctl enable --now argocd-port-forward.service
  EOF
}
