FROM buildpack-deps:stable as base
ENV MACHINE_NAME="container"
WORKDIR /root
COPY bin/install-dotfiles.sh /
RUN /install-dotfiles.sh \
    && apt update -qqy && apt install -yqq sudo && ~/bin/setup.sh \
    && rm -r /var/lib/apt/lists /var/cache/apt/archives /install-dotfiles.sh
ENTRYPOINT ["/root/bin/entrypoint.sh"]
