# kubecui

kubeui makes `kubectl` more user friendly. This is still `kubectl` but enhanced with fzf.

---
## I believe, anybody who is new to kubernetes, must use `kubectl`. Because `kubectl` is the basics.
---

However, kubectl slows you down - requires heavy keyboard typing. In order to alleviate interaction with kubernetes API and describe the fields associated with each supported API resource directly in the Terminal, `kubectl` was complemented by `fzf`.

## Dependencies

* `fzf` (command-line fuzzy finder) - <https://github.com/junegunn/fzf>
* `yq` (portable command-line YAML processor)
* Optional: `tmux` (terminal multiplexer)
* Optional: `tmuxp` (tmux sessions manager)

## Installation
### Dependencies
There is no script which leads you through the process of installation. This is done intentionally because usually tools like apt, snap, yum and so on, require root privileges, and we want the process to be transparent, at least at the earlier stage.

* `fzf` - Follow the installation instructions <https://github.com/junegunn/fzf#installation>
  * **Optional**: advanced kubectl command completion - <https://github.com/junegunn/fzf/wiki/examples#kubectl>
  * For exmaple:
    * k -n Hit [ TAB key ]
    * k get Hit [ TAB key ]
* `yq` - `snap install yq` OR `apt install yq`
* Optional: `apt install tmux tmuxp`

### kubecui init
* `init.sh`
### kubecui
* git clone https://github.com/pymag09/kubecui.git
* chmod +x kubecui.sh
* If for some reason init.sh failed, make sure that ~/.bashrc contains followig lines:
  * source /home/\<PATH\>/kubecui/kubecui.sh
  * export KUI_PATH="/home/\<PATH\>/kubecui"

## Cluster per window
If the optional packages `tmux` and `tmuxp` were installed, you can have each cluster(dev,stg,prod) in separate window without switchig the context.  
The `init.sh` script creates `.tmuxp` folder and copy the `default.yaml` file there. After that, you have to edit the file and make sure that you use actual values instead of < ...abc... >
If everything is ready execute `k start`  
 ![k start](https://github.com/pymag09/kubecui/blob/main/images/tmux_main.png)
Pay attention to the red rectangle. These are your clusters. `*` next to cluster points to the active window/cluster.  
Key combinations you may find helpful:
* **Ctrl+b 1,2,3,n** OR **Ctrl+b w** - switch between windows/clusters
  * ![windows](https://github.com/pymag09/kubecui/blob/main/images/tmux_windows.png)
* **Ctrl+b d** - exit multi-widow session
* **Ctrl+b [** - edit mode. You can move cursor, scroll up/down, select and copy text.
* **Ctrl+r** - if you followed the installation instructions for fzf, most probably you use fzf to browse shell history. If you didn't, you should try, cause it is fun and makes your experience with kubecui more plesant.

## From fzf README file:
### Search syntax

Unless otherwise specified, fzf starts in "extended-search mode" where you can
type in multiple search terms delimited by spaces. e.g. `^music .mp3$ sbtrkt
!fire`

| Token     | Match type                 | Description                          |
| --------- | -------------------------- | ------------------------------------ |
| `sbtrkt`  | fuzzy-match                | Items that match `sbtrkt`            |
| `'wild`   | exact-match (quoted)       | Items that include `wild`            |
| `^music`  | prefix-exact-match         | Items that start with `music`        |
| `.mp3$`   | suffix-exact-match         | Items that end with `.mp3`           |
| `!fire`   | inverse-exact-match        | Items that do not include `fire`     |
| `!^music` | inverse-prefix-exact-match | Items that do not start with `music` |
| `!.mp3$`  | inverse-suffix-exact-match | Items that do not end with `.mp3`    |

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
* k config use-context
  - Singale panel. Switch between kubeconfig contexts
* k config set ns
  - Singale panel. Set default namespace.
* k start
  - starts `cluster per window` session
