#!/bin/bash
set -Eeo pipefail

setup_ssh() {
	mkdir -p "${HOME}/.ssh/sockets"
	eval $(ssh-agent)
	cat "private_dot_ssh/encrypted_private_id_ed25519.asc" | gpg --passphrase "${ENCRYPTION_PASSPHRASE}" --batch -d >"${HOME}/.ssh/id_ed25519"
	chmod 600 "${HOME}/.ssh/id_ed25519"
	ssh-add "${HOME}/.ssh/id_ed25519"
	cp "private_dot_ssh/private_known_hosts" "${HOME}/.ssh/known_hosts"
}

#Install packages on android
install() {
	cd "${HOME}"
	mkdir -p ${HOME}/.local/{bin,share,lib,lib64}
	asdf_install() {
		set -- "$@"
		[[ $(command -v ${2-$1}) ]] && echo "The packages $1 is installed" && return
		asdf plugin add $1 $3
		asdf install $1 latest
		asdf global $1 latest
	}
	# Need asdf to install
	install_with_asdf() {
		asdf_install chezmoi
		echo 'aria2 aria2c,rclone,restic' | tr "," "\n" | xargs -I {} bash -c 'pkg-install.sh NET asdf_install {}'
		echo 'nodejs node,shfmt,shellcheck' | tr "," "\n" | xargs -I {} bash -c 'pkg-install.sh DEV asdf_install {}'
	}
	# need apt to install
	install_with_apt_get() {
		pkg-install.sh BASE apt-get install -qqy --no-install-recommends 7zip sqlite3 lsb-release pip tree
		pkg-install.sh INTERACTIVE apt-get install -qqy --no-install-recommends vim tmux mosh fzf zsh-syntax-highlighting zsh-autosuggestions less
		pkg-install.sh ALL apt-get install -qqy --no-install-recommends ffmpeg yt-dlp
	}
	install_calibre() {
		pkg-install.sh ALL wget -nv -O- https://download.calibre-ebook.com/linux-installer.sh | sh /dev/stdin install_dir="${HOME}/.local" share_dir="${HOME}/.local/share" bin_dir="${HOME}/.local/bin"
	}
	install_oh_my_zsh() {
		pkg-install.sh INTERACTIVE sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --RUNZSH=no --CHSH=yes
	}

	export -f asdf_install install_with_asdf install_with_apt_get install_calibre install_oh_my_zsh
	if [[ $(uname -o) = Android ]]; then
		apt-get update -qqy
		apt-get install -qqy 7zip aria2 chezmoi curl git jq mosh parallel rclone restic shfmt sqlite tmux vim wget gnupg zsh fzf openssh-client
		install_oh_my_zsh
		chezmoi init --ssh 'git@codeberg.org:esperoj/dotfiles.git'
		termux-setup-storage
		termux-change-repo
	fi

	[[ $(uname -o) = *Linux* ]] && {
		# Install packages
		apt-get update -qqy
		pkg-install.sh BASE apt-get install -qqy --no-install-recommends jq parallel curl gnupg git xz-utils unzip bzip2 wget dirmngr openssh-client ca-certificates sudo python3 apt-utils
		# Need for calibre
		pkg-install.sh ALL apt-get install -qqy --no-install-recommends libegl1 libopengl0
		# Need to install oh my zsh
		pkg-install.sh INTERACTIVE apt-get install -qqy --no-install-recommends zsh
		git clone --quiet --depth=1 https://github.com/asdf-vm/asdf.git ~/.asdf --branch master
		. "$HOME/.asdf/asdf.sh"
		echo 'install_with_asdf
    install_with_apt_get
    install_calibre
    install_oh_my_zsh' | parallel {}
	}

	# Post install
	. "$HOME/.asdf/asdf.sh"
	ln -s $(chezmoi source-path)/scripts .
	ln -s $(command -v 7zz) ".local/bin/7z"
	ln -s $(command -v python3) ".local/bin/python"
	mkdir -p "${HOME}/.ssh/sockets"
	chezmoi init --ssh git@codeberg.org:esperoj/dotfiles.git
}

[[ "$1" == install ]] && {
	shift 1
	install "$@"
	return
}

[[ "$1" == setup_ssh ]] && {
	shift 1
	setup_ssh "$@"
	return
}
