# kubecui

kubeui makes `kubectl` more user friendly. This is still `kubectl` but enhanced with fzf.

---

## I believe, anybody who is new to kubernetes, must use `kubectl`. Because `kubectl` is the basics.

---

However, kubectl slows you down - requires heavy keyboard typing. In order to alleviate interaction with kubernetes API and describe the fields associated with each supported API resource directly in the Terminal, `kubectl` was complemented by `fzf`.

## Dependencies

* `fzf` (command-line fuzzy finder) - [https://github.com/junegunn/fzf](https://github.com/junegunn/fzf)
* `yq` (portable command-line YAML processor)
* Optional: `tmux` (terminal multiplexer)
* Optional: `tmuxp` (tmux sessions manager)

## Three modes

### BASIC

In the basic mode you use only the `k` alias in your terminal window. You type commands like `k get pod -A`, `k logs` and others, do what you need to do, like search for pods, deployments, view the logs and so on. Every time you need to type a new command. This mode is what kubecui was made for. This mode makes work with `kubectl` a little easier.

### NORMAL

Usually we work with more than one cluster. Every time in order to switch a context we type `k config use-context` command. It is a tedious and error prone process (you might deploy or delete something in the wrong context). In the NORMAL mode, we work with a simple interface which has 3 windows - dev,stg,prod. To switch between windows the `Ctrl+b w` shortcut is used. We still need to type commands, like being in BASIC mode, but we switch the context by switching the windows. `k start` activates the mode.
The mode is avaliable if we install optional `tmux` and `tmuxp` packages The `init.sh` script creates a `.tmuxp` folder and copies the `default.yaml` file there. After that, you have to edit the file( `~/.tmuxp/default.yaml`) and make sure that you use actual values instead of < ...abc... > When everything is ready execute `k start`

![k start](https://github.com/pymag09/kubecui/blob/main/images/tmux_main.png)
Pay attention to the red rectangle. These are your clusters. `*` next to cluster points to the active window/cluster.Key combinations you may find helpful:

* **Ctrl+b 1,2,3,n** OR **Ctrl+b w** - switch between windows/clusters
  * ![windows](https://github.com/pymag09/kubecui/blob/main/images/tmux_windows.png)
* **Ctrl+b d** - exit multi-widow session
* **Ctrl+b [** - edit mode. You can move cursor, scroll up/down, select and copy text.
* **Ctrl+r** - if you followed the installation instructions for fzf, most probably you use fzf to browse shell history. If you didn't, you should try, cause it is fun and makes your experience with kubecui more plesant.

### DARK_SIDE

The most efficient and the most interactive mode. Requires minimum typing. Unfortunately this mode goes against the main concept of `kubecui`. You don't type commands, rather switch between windows and sessions. You enter this mode by executing `k start`. After `k start` initializes the environment you will be able to switch between sessions. Each session corresponds to a single context (dev,stage or prod). The shortcut for switching between sessions - `Ctrl+b s`. Each session has 10 windows(for pods, deployments, logs, ingresses, configmaps, secrets, services, PV, PVC and one empty window for any commands). Why are there 10 windows? To make it easier to switch between them. Quick switching - `Ctrl+b number from 0-9`. Or `Ctrl+b w`.

* ![windows](https://github.com/pymag09/kubecui/blob/main/images/dmw.png)
  It pops up interface with windows list, use arrow keys to choose the window.

### Docker

How to build and run kubecui (the darkside mode) using docker.

1. **kubectl** must be installed on your laptop. Because **kubecui** must use the same version of it, inside a docker container.
2. There are lines in the Dockerfile:

```
  RUN cp /root/kubecui/tmux-profiles/dev.yaml.init ~/.tmuxp/dev.yaml && sed -i 's/<KUBECONFIG_PATH>/"~\/\.kube\/dev\.yml"/g' ~/.tmuxp/dev.yaml
  RUN cp /root/kubecui/tmux-profiles/stg.yaml.init ~/.tmuxp/stg.yaml&& sed -i 's/<KUBECONFIG_PATH>/"~\/\.kube\/stg\.yml"/g' ~/.tmuxp/stg.yaml
  RUN cp /root/kubecui/tmux-profiles/prod.yaml.init ~/.tmuxp/prod.yaml&& sed -i 's/<KUBECONFIG_PATH>/"~\/\.kube\/prod\.yml"/g' ~/.tmuxp/prod.yaml
```

They add kubeconfig files path and name (~/.kube/dev.yml, ~/.kube/stg.yml, ~/.kube/prod.yml) to the **kubecui** config file (kubecui will search these particular file names). Later, you will mount kubeconfig directory from your laptop to a docker container `-v <HOME_DIR_PATH>/.kube:/root/.kube`, which means your's laptop **/.kube/** directory must contain dev.yml, stg.yml, prod.yml. If you want to use different file names, instead of default ones, you must change them the Dockerfile `sed -i 's/<KUBECONFIG_PATH>/"~\/\.kube\/BLA_BLA_SOME_NAME\.yml"/g'`

3. Build the image: `docker build -t kubecui:latest . `
4. Run kubecui: `docker run -it --rm --name kubecui -v <PATH>/kubectl:/usr/local/bin/kubectl -v <HOME_DIR_PATH>/.kube:/root/.kube  kubecui:latest`

**IMPORTANT**: For AWS EKS clusters you will additionally need `-v <HOME_DIR_PATH>/.aws:/root/.aws`

## Installation

### Dependencies

There is no script which leads you through the process of installation. This is done intentionally because usually tools like apt, snap, yum and so on, require root privileges, and we want the process to be transparent, at least at the earlier stage.

* `fzf` - Follow the installation instructions [https://github.com/junegunn/fzf#installation](https://github.com/junegunn/fzf#installation)
  * **Optional**: advanced kubectl command completion - [https://github.com/junegunn/fzf/wiki/examples#kubectl](https://github.com/junegunn/fzf/wiki/examples#kubectl)
  * For exmaple:
    * k -n Hit [ TAB key ]
    * k get Hit [ TAB key ]
* `yq` - `snap install yq` OR `apt install yq`
* Optional: `apt install tmux tmuxp`

### Clone the repo

* git clone [https://github.com/pymag09/kubecui.git](https://github.com/pymag09/kubecui.git)

### kubecui

* `chmod +x kubecui.sh kui_start.sh`

### kubecui init

* `init.sh`
* `source ~/.bashrc`

## If for some reason init.sh failed

### BASIC mode

make sure that `~/.bashrc` contains this line:

* `source /<PATH>/kubecui.sh`

### NORMAL mode

In addition to the line for BASIC mode, make sure that `~/.bashrc` contains this line too:

* `export KUI_PATH="<the path to the directory where kui_start.sh is>`

Also the `~/.tmuxp` directory must exist and contain the `default.yaml` file. Remmember to update the file and replace < ...abc... > with actual values.
Finally, check the `kui_start.sh` file and make sure that `tmuxp load default` line is uncommented and `tmuxp load dev stg prod` remains commented out

### DARK-SIDE mode

All the same as for NORMAL mode but instead of `default.yaml` the directory `~/.tmuxp` must contain three files instead:

* `dev.yaml`
* `stg.yaml`
* `prod.yaml`

`kui_start.sh`. `tmuxp load default` is commented out. `tmuxp load dev stg prod` is uncommented

## kui_start.sh

Every time you run `k start` it executes `kui_start.sh`. The script initializes the sessions. For example, if you work with AWS EKS and MFA is a part of the authentication process you can put an `awsume` command in the very beginning of the `kui_start.sh`.

# SORRY.

I know that not all of you use bash. I really hope that you know how to do the same for other shells. At this moment I am not able to test `kubecui` for all the most popular shells like zsh.

## From fzf README file:

### Search syntax

Unless otherwise specified, fzf starts in "extended-search mode" where you can
type in multiple search terms delimited by spaces. e.g. `^music .mp3$ sbtrkt !fire`


| Token     | Match type                 | Description                         |
| ----------- | ---------------------------- | ------------------------------------- |
| `sbtrkt`  | fuzzy-match                | Items that match`sbtrkt`            |
| `'wild`   | exact-match (quoted)       | Items that include`wild`            |
| `^music`  | prefix-exact-match         | Items that start with`music`        |
| `.mp3$`   | suffix-exact-match         | Items that end with`.mp3`           |
| `!fire`   | inverse-exact-match        | Items that do not include`fire`     |
| `!^music` | inverse-prefix-exact-match | Items that do not start with`music` |
| `!.mp3$`  | inverse-suffix-exact-match | Items that do not end with`.mp3`    |

## Commands

Most probabaly you are falimiar with or already use `k` alias for `kubectl`. If so, you will be happy to hear, that kubecui is k alias in essence.

* k get \<OBJECT\>
  ![k get pod](https://github.com/pymag09/kubecui/blob/main/images/kgetpod.png)
* k logs
  ![k logs](https://github.com/pymag09/kubecui/blob/main/images/klogs.png)
* k expain
  ![k expain](https://github.com/pymag09/kubecui/blob/main/images/kexplain.png)
* k explain \<OBJECT\>
  ![k explain pod](https://github.com/pymag09/kubecui/blob/main/images/kubecuiexplain.gif)
  ![k explain pod](https://github.com/pymag09/kubecui/blob/main/images/kexplainpod.png)
* k get events --all-namespaces
  - Get all events. sort by first and last seen
* k config use-context
  - Singale panel. Switch between kubeconfig contexts
* k config set ns
  - Singale panel. Set default namespace.
* k start
  - starts `cluster per window` session
