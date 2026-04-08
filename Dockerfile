FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TERM=xterm-256color

RUN apt-get update && apt-get install -y \
    zsh git curl locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

WORKDIR /root

COPY .zshrc /root/.zshrc
COPY setup.sh /root/setup.sh
COPY bored.zsh-theme /root/.oh-my-zsh/custom/themes/bored.zsh-theme

RUN chmod +x /root/setup.sh

CMD ["zsh", "-l"]
