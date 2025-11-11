# My NixOS Host Configuration (`nixos-host-config`)

This is my **private** repository for managing NixOS host-specific configurations. It works with the public `nixos-dev-base` repository to create a fully declarative development environment.

## 1. Initial Setup

Follow these steps for a freshly installed, minimal NixOS system.

### Step 1: On the New NixOS Machine
1.  Log in as `root`.
2.  Set a `root` password to allow `scp`.
    ```bash
    passwd root
    ```
3.  Enable `openssh`.
    ```bash
    nano -w /etc/nixos/configuration.nix
    services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
    };
    nixos-rebuild switch
    ```
4.  Get the machine's IP address.
    ```bash
    ip a
    ```

### (Alternative) Using the Serial Console

As an alternative to the network-based setup (steps 1-4, which **rely on** networking), you can configure the serial console to log in directly. This is especially useful for **headless machines** or VMs before networking is active.

#### 1. Enable Serial Console in NixOS:
Log in as `root` (e.g., **via** the VM's display console) and edit your configuration:

```bash
nano -w /etc/nixos/configuration.nix
boot.kernelParams = [ "console=ttyS0,115200n8" ];
```

#### 2. Apply and Shut Down:
Apply the change and shut down the machine.

```
nixos-rebuild switch
shutdown now
```

#### 3. (For VMs) Attach Serial Hardware: 
If NixOS is running in a VM, you must attach a serial port device through your hypervisor's settings (e.g., VirtualBox, VMware):

> VM Settings > Hardware > Add > Serial Port

(Ensure this port is configured to be accessible from your host machine.)

#### 4. Boot and Connect:
Boot the NixOS machine. From your host laptop, connect using a serial client (picocom or xterm.js):

```bash
picocom -b 115200 /dev/ttyUSB0
```

### Step 2: From Your Laptop (Transfer)
`scp` or `rsync` the entire repository to the new machine's `/root` directory. `rsync` is cleaner.

```bash
git clone https://github.com/r-agatsuma/nixos-host-config.git
cd nixos-host-config
rsync -rlptv --delete ./ root@<nixos-ip>:/root/nixos-host-config
```

As an alternative, use `git`.

```bash
nix-env -iA nixos.git
git clone https://github.com/r-agatsuma/nixos-host-config.git /root/nixos-host-config
cd /root/nixos-host-config
```

### Step 3: On the New NixOS Machine (Run Setup as `root`)
1.  Log in as `root` again.
2.  Run the `setup-host.sh` script. This script will:
    * Back up the original `/etc/nixos`.
    * Copy the machine-specific `hardware-configuration.nix` from the backup.
    * Run the first build (which creates the `dev` user).
    * Move this config repository to its final home (`/home/dev/src/nixos-host-config`).
    * Create the final system symlink (`/etc/nixos`).

```bash
cd /root/nixos-host-config
./setup-host.sh
```

### Step 4: On the New NixOS Machine (Finalize as `dev`)
1.  Log out of `root` and **log in as the new `dev` user**.
2.  Navigate to your new config directory.
    ```bash
    cd ~/src/nixos-host-config
    ```
3.  **Authenticate with GitHub.**
    ```bash
    gh auth login
    ```
4.  Your machine is now fully provisioned and linked to GitHub.

---

## 2. Daily Workflow (Updating the System)

This is a **pull-based** workflow, run *on the NixOS machine* as the `dev` user.

1.  Log in as `dev`.
2.  Navigate to the config directory.
    ```bash
    cd ~/src/nixos-host-config
    ```
3.  Run the `update-host.sh` script to apply the changes.
    ```bash
    ./update-host.sh
    ```

This script runs `sudo nix flake update` (to get the latest `nixpkgs` and `nixos-dev-base`) and then `sudo nixos-rebuild switch` to activate the new configuration.
