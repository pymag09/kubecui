FROM ubuntu

WORKDIR /root
RUN apt update && apt install -y curl git tmux tmuxp unzip vim jq
#
# AWSCLI for EKS clusters
#
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && /root/aws/install
#
# kubecui dependencies
#
RUN git clone https://github.com/junegunn/fzf.git && yes | fzf/install
RUN git clone https://github.com/pymag09/kubecui.git
#
# Add k alias to .bashrc
#
RUN echo "source /root/kubecui/kubecui.sh" >> /root/.bashrc
#
# Init tmux profiles
#
RUN mkdir /root/.tmuxp
RUN cp /root/kubecui/tmux-profiles/dev.yaml.init ~/.tmuxp/dev.yaml && sed -i 's/<KUBECONFIG_PATH>/"~\/\.kube\/dev\.yml"/g' ~/.tmuxp/dev.yaml
RUN cp /root/kubecui/tmux-profiles/stg.yaml.init ~/.tmuxp/stg.yaml&& sed -i 's/<KUBECONFIG_PATH>/"~\/\.kube\/stg\.yml"/g' ~/.tmuxp/stg.yaml
RUN cp /root/kubecui/tmux-profiles/prod.yaml.init ~/.tmuxp/prod.yaml&& sed -i 's/<KUBECONFIG_PATH>/"~\/\.kube\/prod\.yml"/g' ~/.tmuxp/prod.yaml
RUN sed -i '/^#tmuxp load dev.*/s/^#//g' /root/kubecui/kui_start.sh 

CMD /root/kubecui/kui_start.sh
