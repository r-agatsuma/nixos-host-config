{
    boot.loader.grub.enable = false;
    boot.loader.grub.device = "/dev/vda";
    fileSystems."/" = { 
        device = "/dev/vda1";
        fsType = "ext4"; 
    };
}