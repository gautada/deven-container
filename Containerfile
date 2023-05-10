ARG ALPINE_VERSION="latest"

FROM gautada/alpine:$ALPINE_VERSION

# ╭――――――――――――――――――――╮
# │ METADATA           │
# ╰――――――――――――――――――――╯
LABEL source="https://github.com/gautada/code-container.git"
LABEL maintainer="Adam Gautier <adam@gautier.org>"

# ╭――――――――――――――――――――╮
# │ STANDARD CONFIG    │
# ╰――――――――――――――――――――╯

# USER:
ARG USER=coder

ARG UID=1001
ARG GID=1001
RUN /usr/sbin/addgroup -g $GID $USER \
 && /usr/sbin/adduser -D -G $USER -s /bin/zsh -u $UID $USER \
 && /usr/sbin/usermod -aG wheel $USER \
 && /bin/echo "$USER:$USER" | chpasswd

# PRIVILEGE:
COPY wheel  /etc/container/wheel
RUN /bin/ln -fsv /etc/container/wheel /etc/sudoers.d/wheel
# BACKUP:
COPY backup /etc/container/backup

# ENTRYPOINT:
RUN rm -v /etc/container/entrypoint
COPY entrypoint /etc/container/entrypoint

# FOLDERS
RUN /bin/chown -R $USER:$USER /mnt/volumes/container \
 && /bin/chown -R $USER:$USER /mnt/volumes/backup \
 && /bin/chown -R $USER:$USER /var/backup \
 && /bin/chown -R $USER:$USER /tmp/backup

# ╭――――――――――――――――――――╮
# │ APPLICATION        │
# ╰――――――――――――――――――――╯

RUN /sbin/apk add --no-cache build-base yarn npm 
RUN /sbin/apk add --no-cache git
RUN /sbin/apk add --no-cache openssh-client openssh 
RUN /sbin/apk add --no-cache tmux tpm
RUN /sbin/apk add --no-cache neovim neovim-doc
RUN /sbin/apk add --no-cache zsh
RUN /sbin/apk add --no-cache nerd-fonts-all
RUN /sbin/apk add --no-cache buildah fuse-overlayfs podman py3-pip

RUN /sbin/apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl

RUN /usr/sbin/usermod --add-subuids 100000-165535 $USER \
 && /usr/sbin/usermod --add-subgids 100000-165535 $USER

RUN /usr/bin/pip3 install podman-compose

RUN /bin/ln -fsv /mnt/volumes/configmaps/kubectl.cfg /etc/container/kubectl.cfg \
 && /bin/ln -fsv /mnt/volumes/container/kubectl.cfg /mnt/volumes/configmaps/kubectl.cfg \
 && /bin/mkdir -p /home/$USER/.kube \
 && /bin/ln -fsv /etc/container/kubectl.cfg /home/$USER/.kube/config

RUN /bin/ln -fsv /etc/container/git-config /etc/gitconfig \
 && /bin/ln -fsv /mnt/volumes/configmaps/git-config /etc/container/git-config \
 && /bin/ln -fsv /mnt/volumes/container/git-config /mnt/volumes/configmaps/git-config

RUN /bin/ln -fsv /mnt/volumes/secrets/container/git-credentials \
                 /etc/container/git-credentials \
 && /bin/ln -fsv /mnt/volumes/container/git-credentials \
                 /mnt/volumes/secrets/container/git-credentials

RUN /bin/ln -fsv /mnt/volumes/secrets/container/ca.crt /etc/container/ca.crt \
 && /bin/ln -fsv /mnt/volumes/container/ca.crt /mnt/volumes/secrets/container/ca.crt 

RUN /bin/ln -fsv /mnt/volumes/secrets/container/ca.key /etc/container/ca.key \
 && /bin/ln -fsv /mnt/volumes/container/ca.key /mnt/volumes/secrets/container/ca.key

RUN mkdir -p /mnt/volumes/compose/container /mnt/volumes/compose/backup

# RUN /bin/ln -fsv /mnt/volumes/container /Workspace
COPY --chown=$USER tmux.conf /home/$USER/.config/tmux/tmux.conf

RUN chown $USER:$USER -R /home/$USER
# ╭――――――――――――――――――――╮
# │ CONTAINER          │
# ╰――――――――――――――――――――╯

USER $USER
VOLUME /mnt/volumes/backup
VOLUME /mnt/volumes/configmaps
VOLUME /mnt/volumes/container
EXPOSE 8080/tcp
WORKDIR /home/$USER

# RUN /bin/mkdir -p /home/$USER/.config/git
RUN /bin/ln -fsv /home/$USER/.config/repo/public/git /home/$USER/.config/git
RUN /bin/ln -fsv /home/$USER/.config/git/config /home/$USER/.gitconfig
RUN /bin/ln -fsv /home/$USER/.config/git/credentials /home/$USER/.git-credentials

RUN /bin/ln -fsv /mnt/volumes/container/workspace Workspace
RUN /bin/mkdir -p /home/$USER/.config/repo/public
RUN git clone https://github.com/gautada/config.git /home/$USER/.config/repo/public

RUN /bin/ln -fsv /home/$USER/.config/repo/public/nvim /home/$USER/.config/nvim

RUN /bin/ln -fsv /home/$USER/.config/repo/public/zsh /home/$USER/.config/zsh
RUN /bin/ln -fsv /home/$USER/.config/zsh/rc /home/$USER/.config/zshrc
RUN /bin/ln -fsv /mnt/volumes/container/users/coder/zsh/history /home/$USER/.config/.zsh_history

# RUN /bin/mkdir -p /home/$USER/.config/git/ \
#  && /bin/ln -fsv /home/$USER/.config/git/config /home/$USER/.gitconfig \
#  && /bin/ln -fsv /mnt/volumes/configmaps/git-config  /home/$USER/.config/git/config \
#  && /bin/ln -fsv /home/$USER/.config/git/credentials /home/$USER/.git-credentials 


RUN /bin/mkdir -p /tmp/podman-run-1001/podman
RUN /usr/bin/podman system connection add sock unix:///tmp/podman-run-1001/podman/podman.sock
RUN /usr/bin/podman system connection default sock

RUN /usr/bin/yarn global add wetty
