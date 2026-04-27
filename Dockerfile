FROM osrf/ros:humble-desktop-full

RUN apt-get update \
    && apt-get install -y \ 
    vim \
    iputils-ping \
    nano \
    bash-completion \
    python3-argcomplete \
    && rm -rf /var/lib/apt/lists/*

COPY config/ /site_config/

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
&& useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
&& mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config


RUN apt-get update \
    && apt-get install sudo -y \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*
    
    
RUN mkdir -p /home/$USERNAME/dev_ws/src/my_bot \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME/dev_ws

COPY entrypoint.sh /entrypoint.sh
COPY bashrc /home/${USERNAME}/.bashrc

ENTRYPOINT [ "/bin/bash", "/entrypoint.sh" ]

CMD [ "bash" ]