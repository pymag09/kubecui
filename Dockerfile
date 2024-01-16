FROM ubuntu:mantic

WORKDIR /root
RUN apt update && apt install -y curl git tmux tmuxp unzip vim jq
#
# AWSCLI for EKS clusters
#
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && /root/aws/install
#
# trivy scanner
#
RUN curl -L0 "https://github.com/aquasecurity/trivy/releases/download/v0.48.3/trivy_0.48.3_Linux-64bit.deb" -o "trivy.deb" && dpkg -i trivy.deb
#
# kubecui dependencies
#
RUN git clone https://github.com/junegunn/fzf.git && yes | fzf/install
RUN git clone https://github.com/pymag09/kubecui.git
#
# Add k alias to .bashrc
#
RUN echo "export KUI_PATH=/root/kubecui" >> /root/.bashrc
RUN echo "export FZF_DEFAULT_OPTS=\"--layout=reverse --border\"" >> /root/.bashrc
RUN echo "source /root/kubecui/kubecui.sh" >> /root/.bashrc
#
# Init tmux profiles
#
RUN mkdir /root/.tmuxp
RUN cp /root/kubecui/tmux-profiles/dev.yaml.init ~/.tmuxp/dev.yaml && sed -i 's/<KUBECONFIG_PATH>/"\/root\/\.kube\/dev\.yml"/g' ~/.tmuxp/dev.yaml
RUN cp /root/kubecui/tmux-profiles/stg.yaml.init ~/.tmuxp/stg.yaml&& sed -i 's/<KUBECONFIG_PATH>/"\/root\/\.kube\/stg\.yml"/g' ~/.tmuxp/stg.yaml
RUN cp /root/kubecui/tmux-profiles/prod.yaml.init ~/.tmuxp/prod.yaml&& sed -i 's/<KUBECONFIG_PATH>/"\/root\/\.kube\/prod\.yml"/g' ~/.tmuxp/prod.yaml
RUN sed -i '/^#tmuxp load dev.*/s/^#//g' /root/kubecui/kui_start.sh 

CMD ["/usr/bin/bash", "/root/kubecui/kui_start.sh"]
