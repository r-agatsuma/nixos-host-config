# My NixOS Host Configuration (`nixos-host-config`)

NixOSのホスト固有の設定を管理するためのリポジトリである．

## 1. 初期セットアップ

新規インストールされた最小構成のNixOSシステムに対して、以下の手順を実行する．

### Step 1: 新しいNixOSマシン上での操作
1.  `root` としてログインする．
2.  `scp` を許可するために `root` パスワードを設定する．
    ```bash
    passwd root
    ```
3.  `openssh` を有効にする．
    ```bash
    nano -w /etc/nixos/configuration.nix
    services.openssh = {
        enable = true;
        settings.PermitRootLogin = "yes";
    };
    nixos-rebuild switch
    ```
4.  マシンのIPアドレスを取得する．
    ```bash
    ip a
    ```

### （代替手段）シリアルコンソールの使用

ネットワークベースのセットアップ（Step 1-4、これらはネットワークに依存している）の代替手段として，シリアルコンソールを設定して直接ログインできる．
これはヘッドレスマシンや，ネットワークが有効になる前のVM（仮想マシン）で特に便利である．

#### 1. NixOSでシリアルコンソールを有効にする:
`root` としてログインし（例：VMのディスプレイコンソール経由など），設定ファイルを編集する．

```bash
nano -w /etc/nixos/configuration.nix
boot.kernelParams = [ "console=ttyS0,115200n8" ];
```

#### 2. 適用してシャットダウンする:
変更を適用し，マシンをシャットダウンする.

```
nixos-rebuild switch
shutdown now
```

#### 3. （VMの場合）シリアルハードウェアを接続する
NixOSがVMで動作している場合，ハイパーバイザーの設定（例：Proxmox VE）からシリアルポートデバイスを接続する必要がある．

VM Settings > Hardware > Add > Serial Port

（このポートがホストマシンからアクセス可能に設定されていることを確認すること）

#### 4. 起動して接続する:
NixOSマシンを起動する．ホストのラップトップから，シリアルクライアント（picocomやxterm.js）を使用して接続する．

```bash
picocom -b 115200 /dev/ttyUSB0
```

### Step 2: ラップトップからの操作（転送）
リポジトリ全体を新しいマシンの `/root` ディレクトリに `scp` または `rsync` する．`rsync` の方がクリーンである．

```bash
git clone https://github.com/r-agatsuma/nixos-host-config.git
cd nixos-host-config
rsync -rlptv --delete ./ root@<nixos-ip>:/root/nixos-host-config
```

代替手段として，`git` も使用できる．

```bash
nix-env -iA nixos.git
git clone https://github.com/r-agatsuma/nixos-host-config.git /root/nixos-host-config
cd /root/nixos-host-config
```

### Step 3: 新しいNixOSマシン上での操作 (`root` としてセットアップを実行)
1.  再度 `root` としてログインする.
2.  SSH公開鍵を配置する．
3.  `setup-host.sh` スクリプトを実行する．スクリプトは以下を実行する．
    * 元の `/etc/nixos` をバックアップ
    * バックアップからマシン固有の `hardware-configuration.nix` をコピー
    * 初回のビルドを実行（これにより dev ユーザーが作成される）
    * この設定リポジトリを最終的な配置場所に移動 (`/home/dev/src/nixos-host-config`)
    * 最終的なシステムシンボリックリンクを作成 (`/etc/nixos`).

```bash
cd /root/nixos-host-config
./setup-host.sh
```

### Step 4: 新しいNixOSマシン上での操作 (`dev`として仕上げ)
1.  `root` からログアウトし，新しい `dev` ユーザーとしてログインする．
2.  新しい設定ディレクトリに移動する．
    ```bash
    cd ~/src/nixos-host-config
    ```
3.  GitHub認証を行う．
    ```bash
    gh auth login
    ```
4.  Tailscale認証を行う．
    ```bash
    tailscale up
    ```
5.  コンソールログイン用のパスワードを設定する．
    ```bash
    sudo mkdir -p /etc/nixos/secrets
    sudo sh -c 'mkpasswd -m sha-512 > /etc/nixos/secrets/console-password'
    sudo chmod 600 /etc/nixos/secrets/console-password
    ```
6.  これでマシンのプロビジョニングが完了した．

---

## 2. 日々のワークフロー（システムの更新）

これはプル型のワークフローであり，NixOSマシン上で `dev`ユーザーとして実行する．

1.  `dev` としてログインする
2.  設定ディレクトリに移動する．
    ```bash
    cd ~/src/nixos-host-config
    ```
3.  `update-host.sh` スクリプトを実行して変更を適用する．
    ```bash
    ./update-host.sh
    ```

このスクリプトは `sudo nix flake update` を実行し，その後 `sudo nixos-rebuild switch` を実行して新しい設定を有効化する．
