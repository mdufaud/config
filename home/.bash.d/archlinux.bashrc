antivirus_update()
{
    freshclam
}

antivirus_scan()
{
    clamscan -r --bell -i "$@"
}

aur_install()
{
    makepkg --syncdeps --noconfirm --install --clean
}

wireguard_add()
{
    mcli connection import type wireguard file "$1"
}

pacman_update()
{
    sudo pacman -Syu
}

pacman_install()
{
    sudo pacman -S --noconfirm "$@"
}

pacman_remove()
{
    sudo pacman -R --noconfirm "$@"
}

pacman_search()
{
    pacman -Ss "$@"
}

pacman_info()
{
    pacman -Qi "$@"
}

pacman_list()
{
    pacman -Q "$@"
}

pacman_list_orphans()
{
    pacman -Qdtq
}

pacman_list_installed()
{
    pacman -Qe
}

pacman_list_all()
{
    pacman -Q
}